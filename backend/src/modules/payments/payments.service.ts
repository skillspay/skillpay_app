import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import Stripe from 'stripe';
import { PaymentGateway, PaymentMethod } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);
  private readonly stripe: Stripe;
  private readonly paypalBaseUrl: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.stripe = new Stripe(this.config.get<string>('stripe.secretKey')!, {
      apiVersion: '2024-04-10' as any,
    });
    this.paypalBaseUrl =
      this.config.get<string>('paypal.mode') === 'live'
        ? 'https://api-m.paypal.com'
        : 'https://api-m.sandbox.paypal.com';
  }

  // ─── Stripe Integration ──────────────────────────────────────────────────────

  async createStripePaymentIntent(bookingId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { application: true },
    });

    if (!booking) {
      throw new NotFoundException(`Booking ${bookingId} not found`);
    }

    const price = Number(booking.application.price);
    const amountInCents = Math.round(price * 100);

    // Create payment intent on Stripe
    const intent = await this.stripe.paymentIntents.create({
      amount: amountInCents,
      currency: 'usd',
      metadata: { bookingId },
    });

    // Save payment record
    const payment = await this.prisma.payment.create({
      data: {
        bookingId,
        homeownerId: booking.homeownerId,
        artisanId: booking.artisanId,
        reference: uuidv4(),
        amount: price,
        gateway: PaymentGateway.STRIPE,
        paymentMethod: PaymentMethod.CARD,
        gatewayRef: intent.id,
        status: 'PENDING',
      },
    });

    return {
      paymentId: payment.id,
      clientSecret: intent.client_secret,
      publishableKey: this.config.get<string>('stripe.publishableKey'),
    };
  }

  async handleStripeWebhook(rawBody: Buffer, signature: string) {
    const webhookSecret = this.config.get<string>('stripe.webhookSecret');
    let event: Stripe.Event;

    try {
      event = this.stripe.webhooks.constructEvent(rawBody, signature, webhookSecret!);
    } catch (err: any) {
      this.logger.error(`Webhook signature verification failed: ${err.message}`);
      throw new BadRequestException(`Webhook Error: ${err.message}`);
    }

    if (event.type === 'payment_intent.succeeded') {
      const intent = event.data.object as Stripe.PaymentIntent;
      await this.completePayment(intent.id);
    }

    return { received: true };
  }

  // ─── PayPal Integration ──────────────────────────────────────────────────────

  private async getPayPalAccessToken(): Promise<string> {
    const clientId = this.config.get<string>('paypal.clientId');
    const clientSecret = this.config.get<string>('paypal.clientSecret');
    const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

    const res = await fetch(`${this.paypalBaseUrl}/v1/oauth2/token`, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${credentials}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    });

    if (!res.ok) {
      throw new Error(`Failed to generate PayPal token: ${res.statusText}`);
    }

    const data = await res.json();
    return data.access_token;
  }

  async createPayPalOrder(bookingId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { application: true },
    });

    if (!booking) {
      throw new NotFoundException(`Booking ${bookingId} not found`);
    }

    const price = Number(booking.application.price);
    const token = await this.getPayPalAccessToken();

    const response = await fetch(`${this.paypalBaseUrl}/v2/checkout/orders`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        intent: 'CAPTURE',
        purchase_units: [
          {
            amount: {
              currency_code: 'USD',
              value: price.toFixed(2),
            },
            custom_id: bookingId,
          },
        ],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      this.logger.error(`PayPal order creation failed: ${errorText}`);
      throw new BadRequestException('Failed to create PayPal order');
    }

    const order = await response.json();

    // Create payment entry
    await this.prisma.payment.create({
      data: {
        bookingId,
        homeownerId: booking.homeownerId,
        artisanId: booking.artisanId,
        reference: uuidv4(),
        amount: price,
        gateway: PaymentGateway.PAYPAL,
        paymentMethod: PaymentMethod.PAYPAL,
        gatewayRef: order.id,
        status: 'PENDING',
      },
    });

    return order;
  }

  async capturePayPalOrder(orderId: string) {
    const token = await this.getPayPalAccessToken();

    const response = await fetch(`${this.paypalBaseUrl}/v2/checkout/orders/${orderId}/capture`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      this.logger.error(`PayPal capture failed: ${errorText}`);
      throw new BadRequestException('Failed to capture PayPal order');
    }

    const capture = await response.json();

    if (capture.status === 'COMPLETED') {
      await this.completePayment(orderId);
      return { status: 'COMPLETED' };
    }

    return { status: capture.status };
  }

  // ─── Helper Completion Logic ───────────────────────────────────────────────

  private async completePayment(gatewayRef: string) {
    const payment = await this.prisma.payment.findFirst({
      where: { gatewayRef },
    });

    if (!payment) {
      this.logger.warn(`Payment record with gatewayRef ${gatewayRef} not found`);
      return;
    }

    if (payment.status === 'COMPLETED') return;

    await this.prisma.$transaction(async (tx) => {
      // 1. Update Payment status
      await tx.payment.update({
        where: { id: payment.id },
        data: { status: 'COMPLETED' },
      });

      // 2. Update Booking status to CONFIRMED or update payment status on it
      await tx.booking.update({
        where: { id: payment.bookingId },
        data: { status: 'CONFIRMED' },
      });

      // 3. Create or update Artisan wallet balance (payout)
      const artisanWallet = await tx.wallet.findUnique({
        where: { userId: payment.artisanId },
      });

      let wallet;
      if (!artisanWallet) {
        wallet = await tx.wallet.create({
          data: {
            userId: payment.artisanId,
            balance: payment.amount,
          },
        });
      } else {
        wallet = await tx.wallet.update({
          where: { userId: payment.artisanId },
          data: {
            balance: { increment: payment.amount },
          },
        });
      }

      // 4. Create WalletTransaction log
      await tx.walletTransaction.create({
        data: {
          walletId: wallet.id,
          amount: payment.amount,
          type: 'CREDIT',
          reference: uuidv4(),
          description: `Payout for booking #${payment.bookingId}`,
        },
      });
    });

    this.logger.log(`Payment Completed: Ref ${payment.reference} for Booking ${payment.bookingId}`);
  }
}
