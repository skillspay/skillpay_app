import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class WalletService {
  constructor(private readonly prisma: PrismaService) {}

  async getWallet(userId: string) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
      include: { transactions: { orderBy: { createdAt: 'desc' } } },
    });
    if (!wallet) {
      // Lazy init wallet
      return this.prisma.wallet.create({
        data: { userId, balance: 0 },
        include: { transactions: true },
      });
    }
    return wallet;
  }

  async getTransactions(userId: string) {
    const wallet = await this.getWallet(userId);
    return this.prisma.walletTransaction.findMany({
      where: { walletId: wallet.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  async credit(userId: string, amount: number, description: string = 'Wallet credit') {
    const wallet = await this.getWallet(userId);

    return this.prisma.$transaction(async (tx) => {
      const updatedWallet = await tx.wallet.update({
        where: { userId },
        data: { balance: { increment: amount } },
      });

      await tx.walletTransaction.create({
        data: {
          walletId: updatedWallet.id,
          amount,
          type: 'CREDIT',
          reference: uuidv4(),
          description,
        },
      });

      return updatedWallet;
    });
  }
  // ─── Bank Accounts ────────────────────────────────────────────────────────

  async getBankAccounts(userId: string) {
    return this.prisma.bankAccount.findMany({ where: { userId } });
  }

  async addBankAccount(userId: string, data: { bankName: string; accountName: string; accountNumber: string; isDefault?: boolean }) {
    if (data.isDefault) {
      await this.prisma.bankAccount.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    } else {
      const existing = await this.prisma.bankAccount.count({ where: { userId } });
      if (existing === 0) data.isDefault = true;
    }
    return this.prisma.bankAccount.create({
      data: { ...data, userId },
    });
  }

  async deleteBankAccount(userId: string, id: string) {
    const bank = await this.prisma.bankAccount.findUnique({ where: { id } });
    if (!bank || bank.userId !== userId) throw new NotFoundException('Bank account not found');
    return this.prisma.bankAccount.delete({ where: { id } });
  }

  // ─── Withdrawals ──────────────────────────────────────────────────────────
  async requestWithdrawal(userId: string, amount: number, bankAccountId?: string) {
    const wallet = await this.getWallet(userId);
    
    let bank;
    if (bankAccountId) {
      bank = await this.prisma.bankAccount.findUnique({ where: { id: bankAccountId } });
    } else {
      bank = await this.prisma.bankAccount.findFirst({ where: { userId, isDefault: true } }) || 
             await this.prisma.bankAccount.findFirst({ where: { userId } });
    }

    if (!bank || bank.userId !== userId) {
      throw new BadRequestException('Please add a bank account before withdrawing');
    }

    const pendingRequests = await this.prisma.withdrawalRequest.findMany({
      where: { userId, status: 'PENDING' },
    });
    const pendingTotal = pendingRequests.reduce((sum, req) => sum + Number(req.amount), 0);
    
    if (Number(wallet.balance) < amount + pendingTotal) {
      throw new BadRequestException('Insufficient balance considering pending withdrawals');
    }

    return this.prisma.withdrawalRequest.create({
      data: {
        userId,
        amount,
        bankName: bank.bankName,
        accountName: bank.accountName,
        accountNumber: bank.accountNumber,
        status: 'PENDING',
      },
    });
  }
}
