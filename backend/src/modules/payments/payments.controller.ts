import { Controller, Get, Post, Body, Req, Headers, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { Public } from '../../common/decorators/public.decorator';
import { Request } from 'express';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

@ApiTags('Payments')
@UseGuards(SupabaseAuthGuard)
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Public()
  @Get('stripe/config')
  @ApiOperation({ summary: 'Get Stripe publishable configuration' })
  getStripeConfig() {
    return this.paymentsService.getStripeConfig();
  }

  @ApiBearerAuth('supabase-jwt')
  @Post('stripe/create-intent')
  @ApiOperation({ summary: 'Create Stripe PaymentIntent' })
  createStripeIntent(
    @Body() body: { bookingId: string; amount?: number },
  ) {
    return this.paymentsService.createStripePaymentIntent(body);
  }

  @ApiBearerAuth('supabase-jwt')
  @Post('stripe/refund')
  @ApiOperation({ summary: 'Refund a Stripe payment (Admin/Support)' })
  refundStripePayment(
    @Body('paymentId') paymentId: string,
    @Body('reason') reason?: string,
  ) {
    return this.paymentsService.refundStripePayment(paymentId, reason);
  }

  @Public()
  @Post('stripe/webhook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Stripe Webhook endpoint' })
  async handleStripeWebhook(
    @Req() req: Request & { rawBody?: Buffer },
    @Headers('stripe-signature') signature: string,
  ) {
    return this.paymentsService.handleStripeWebhook(req.rawBody as Buffer, signature);
  }

  @ApiBearerAuth('supabase-jwt')
  @Post('paypal/create-order')
  @ApiOperation({ summary: 'Create PayPal Order' })
  createPayPalOrder(@Body('bookingId') bookingId: string) {
    return this.paymentsService.createPayPalOrder(bookingId);
  }

  @ApiBearerAuth('supabase-jwt')
  @Post('paypal/capture-order')
  @ApiOperation({ summary: 'Capture PayPal Order' })
  capturePayPalOrder(@Body('orderId') orderId: string) {
    return this.paymentsService.capturePayPalOrder(orderId);
  }
}
