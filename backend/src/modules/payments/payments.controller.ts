import { Controller, Post, Body, Req, Headers, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { Public } from '../../common/decorators/public.decorator';
import { Request } from 'express';

@ApiTags('Payments')
@UseGuards(SupabaseAuthGuard)
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @ApiBearerAuth('supabase-jwt')
  @Post('stripe/create-intent')
  @ApiOperation({ summary: 'Create Stripe PaymentIntent' })
  createStripeIntent(@Body('bookingId') bookingId: string) {
    return this.paymentsService.createStripePaymentIntent(bookingId);
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
