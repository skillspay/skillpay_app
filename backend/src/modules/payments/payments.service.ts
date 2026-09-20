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

  async createStripePaymentIntent(data: {
    bookingId: string;
    amount?: number;
  }) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: data.bookingId },
      include: { application: true, job: true },
    });

    if (!booking) {
      throw new NotFoundException(`Booking ${data.bookingId} not found`);
    }

    const price = data.amount && data.amount > 0
      ? Number(data.amount)
      : (booking.application?.price ? Number(booking.application.price) : Number(booking.job?.budget ?? 0));

    if (price <= 0) {
      throw new BadRequestException('Payment amount must be greater than zero');
    }

    const amountInCents = Math.round(price * 100);

    // Create payment intent on Stripe
    const intent = await this.stripe.paymentIntents.create({
      amount: amountInCents,
      currency: 'usd',
      metadata: {
        bookingId: booking.id,
        jobId: booking.jobId,
        artisanId: booking.artisanId,
        homeownerId: booking.homeownerId,
      },
    });

    // Check if payment already exists for this booking
    const existing = await this.prisma.payment.findUnique({
      where: { bookingId: booking.id },
    });

    let payment;
    if (existing) {
      payment = await this.prisma.payment.update({
        where: { id: existing.id },
        data: {
          amount: price,
          gateway: PaymentGateway.STRIPE,
          paymentMethod: PaymentMethod.CARD,
          gatewayRef: intent.id,
          status: 'PENDING',
        },
      });
    } else {
      payment = await this.prisma.payment.create({
        data: {
          bookingId: booking.id,
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
    }

    return {
      paymentId: payment.id,
      clientSecret: intent.client_secret,
      publishableKey: this.config.get<string>('stripe.publishableKey'),
      amount: price,
      currency: 'usd',
    };
  }

  getStripeConfig() {
    const publishableKey = this.config.get<string>('stripe.publishableKey') || '';
    const secretKey = this.config.get<string>('stripe.secretKey') || '';
    const isConfigured = secretKey.length > 0 && !secretKey.includes('placeholder');
    return {
      publishableKey,
      isConfigured,
      mode: publishableKey.startsWith('pk_live') ? 'live' : 'test',
    };
  }

  async refundStripePayment(paymentId: string, reason?: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
    });

    if (!payment) {
      throw new NotFoundException(`Payment ${paymentId} not found`);
    }

    if (payment.status === 'REFUNDED') {
      throw new BadRequestException('Payment is already refunded');
    }

    if (payment.gateway !== PaymentGateway.STRIPE || !payment.gatewayRef) {
      throw new BadRequestException('Payment is not a Stripe transaction with valid gatewayRef');
    }

    let refund: Stripe.Refund;
    try {
      refund = await this.stripe.refunds.create({
        payment_intent: payment.gatewayRef,
        reason: (reason as any) || 'requested_by_customer',
      });
    } catch (err: any) {
      this.logger.error(`Stripe refund failed: ${err.message}`);
      throw new BadRequestException(`Stripe refund error: ${err.message}`);
    }

    await this.prisma.payment.update({
      where: { id: paymentId },
      data: { status: 'REFUNDED' },
    });

    this.logger.log(`Payment refunded: ${paymentId} (Stripe Refund ${refund.id})`);

    return {
      success: true,
      refundId: refund.id,
      status: refund.status,
      paymentId,
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

    switch (event.type) {
      case 'payment_intent.succeeded': {
        const intent = event.data.object as Stripe.PaymentIntent;
        await this.completePayment(intent.id);
        break;
      }
      case 'payment_intent.payment_failed': {
        const intent = event.data.object as Stripe.PaymentIntent;
        await this.prisma.payment.updateMany({
          where: { gatewayRef: intent.id },
          data: { status: 'FAILED' },
        });
        this.logger.warn(`PaymentIntent failed: ${intent.id}`);
        break;
      }
      case 'charge.refunded': {
        const charge = event.data.object as Stripe.Charge;
        if (charge.payment_intent) {
          const intentId = typeof charge.payment_intent === 'string' ? charge.payment_intent : charge.payment_intent.id;
          await this.prisma.payment.updateMany({
            where: { gatewayRef: intentId },
            data: { status: 'REFUNDED' },
          });
        }
        break;
      }
      default:
        this.logger.log(`Unhandled Stripe event type: ${event.type}`);
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
