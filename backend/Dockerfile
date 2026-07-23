FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source and generate Prisma client
COPY prisma ./prisma/
RUN npx prisma generate

# Build TypeScript
COPY . .
RUN npm run build

# ─── Production image ─────────────────────────────────────────────────────────
FROM node:20-alpine AS production

WORKDIR /app

# Only install production deps
COPY package*.json ./
RUN npm ci --omit=dev

# Copy built app and Prisma client
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY prisma ./prisma/

# Railway injects PORT — default to 3000
ENV PORT=3000
EXPOSE 3000

# Run migrations then start
CMD npx prisma migrate deploy && node dist/main
