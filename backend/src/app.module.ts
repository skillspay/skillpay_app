import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from './config/config.module';
import { PrismaModule } from './prisma/prisma.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';

// Feature modules
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { HomeownersModule } from './modules/homeowners/homeowners.module';
import { ArtisansModule } from './modules/artisans/artisans.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { JobsModule } from './modules/jobs/jobs.module';
import { ApplicationsModule } from './modules/applications/applications.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { ChatModule } from './modules/chat/chat.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { WalletModule } from './modules/wallet/wallet.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { StorageModule } from './modules/storage/storage.module';
import { AdminModule } from './modules/admin/admin.module';

// Guard
import { SupabaseAuthGuard } from './modules/auth/guards/supabase-auth.guard';

@Module({
  imports: [
    // Core infrastructure (global)
    ConfigModule,
    PrismaModule,

    // Feature modules
    AuthModule,
    UsersModule,
    HomeownersModule,
    ArtisansModule,
    CategoriesModule,
    JobsModule,
    ApplicationsModule,
    BookingsModule,
    ChatModule,
    PaymentsModule,
    WalletModule,
    NotificationsModule,
    ReviewsModule,
    StorageModule,
    AdminModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    // Register SupabaseAuthGuard globally so all modules can inject it.
    // ConfigModule and PrismaModule are @Global() so their services are
    // available here without explicit imports.
    {
      provide: APP_GUARD,
      useClass: SupabaseAuthGuard,
    },
  ],
})
export class AppModule {}
