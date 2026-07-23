import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { WalletService } from './wallet.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/request-with-user.interface';

@ApiTags('Wallet')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard)
@Controller('wallet')
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  // Flutter calls GET /wallet/me
  @Get('me')
  @ApiOperation({ summary: 'Get current user wallet' })
  getWalletMe(@CurrentUser() user: AuthenticatedUser) {
    return this.walletService.getWallet(user.id);
  }

  // Also support GET /wallet for admin/web
  @Get()
  @ApiOperation({ summary: 'Get current user wallet (alias)' })
  getWallet(@CurrentUser() user: AuthenticatedUser) {
    return this.walletService.getWallet(user.id);
  }

  @Get('transactions')
  @ApiOperation({ summary: 'Get wallet transactions' })
  getTransactions(@CurrentUser() user: AuthenticatedUser) {
    return this.walletService.getTransactions(user.id);
  }

  @Post('withdraw')
  @ApiOperation({ summary: 'Request withdrawal from wallet' })
  withdraw(
    @CurrentUser() user: AuthenticatedUser,
    @Body('amount') amount: number,
  ) {
    return this.walletService.withdraw(user.id, amount);
  }
}
