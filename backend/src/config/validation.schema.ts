import * as Joi from 'joi';

export const validationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'production', 'test')
    .default('development'),
  PORT: Joi.number().default(3000),
  API_PREFIX: Joi.string().default('api/v1'),
  CORS_ORIGINS: Joi.string().default('http://localhost:5173'),

  // Database
  DATABASE_URL: Joi.string().required(),

  // Supabase — keep required but allow empty string so app starts and shows config error in logs
  SUPABASE_URL: Joi.string().uri().required(),
  SUPABASE_ANON_KEY: Joi.string().required(),
  SUPABASE_SERVICE_ROLE_KEY: Joi.string().required(),
  SUPABASE_JWT_SECRET: Joi.string().required(),

  // JWT (admin sessions)
  JWT_SECRET: Joi.string().min(8).required(),
  JWT_EXPIRES_IN: Joi.string().default('7d'),

  // Stripe
  STRIPE_SECRET_KEY: Joi.string().optional().default('sk_test_placeholder'),
  STRIPE_WEBHOOK_SECRET: Joi.string().optional().default('whsec_placeholder'),
  STRIPE_PUBLISHABLE_KEY: Joi.string().optional().default('pk_test_placeholder'),

  // PayPal
  PAYPAL_CLIENT_ID: Joi.string().optional().default('paypal_client_placeholder'),
  PAYPAL_CLIENT_SECRET: Joi.string().optional().default('paypal_secret_placeholder'),
  PAYPAL_MODE: Joi.string().valid('sandbox', 'live').default('sandbox'),

  // Storage
  STORAGE_BUCKET_AVATARS: Joi.string().default('avatars'),
  STORAGE_BUCKET_JOB_IMAGES: Joi.string().default('job-images'),
  STORAGE_BUCKET_DOCUMENTS: Joi.string().default('verification-documents'),
  STORAGE_BUCKET_CHAT: Joi.string().default('chat-attachments'),

  // Firebase
  FIREBASE_PROJECT_ID: Joi.string().optional(),
  FIREBASE_CLIENT_EMAIL: Joi.string().email().optional(),
  FIREBASE_PRIVATE_KEY: Joi.string().optional(),

  // Admin seed
  ADMIN_EMAIL: Joi.string().email().optional(),
  ADMIN_PASSWORD: Joi.string().min(8).optional(),
});
