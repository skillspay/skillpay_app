import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/**
 * Marks a route as public — bypasses the SupabaseAuthGuard.
 *
 * Usage:
 *   @Public()
 *   @Post('register')
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
