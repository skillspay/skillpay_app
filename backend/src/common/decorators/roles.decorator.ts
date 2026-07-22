import { SetMetadata } from '@nestjs/common';
import { Role } from '@prisma/client';

export const ROLES_KEY = 'roles';

/**
 * Restricts a route to one or more roles.
 *
 * Usage:
 *   @Roles(Role.ADMIN, Role.SUPER_ADMIN)
 *   @UseGuards(SupabaseAuthGuard, RolesGuard)
 */
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);
