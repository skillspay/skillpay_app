import { Request } from 'express';
import { Role, UserStatus } from '@prisma/client';

export interface AuthenticatedUser {
  id: string;            // Skillpay DB user.id (UUID)
  supabaseUserId: string;
  email: string;
  role: Role;
  status: UserStatus;
  isVerified: boolean;
}

export interface RequestWithUser extends Request {
  user: AuthenticatedUser;
}
