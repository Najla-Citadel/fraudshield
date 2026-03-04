# --- Stage 1: Build ---
FROM node:20.18-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install ALL dependencies (including devDependencies)
RUN npm ci

# Copy source and build
COPY . .
RUN npx prisma generate
RUN npm run build

# --- Stage 2: Production ---
FROM node:20.18-alpine AS runner

WORKDIR /app

# Set production environment
ENV NODE_ENV=production

# Install only production dependencies
# we need prisma in production to run migrations
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci --only=production && npm cache clean --force

# Copy built artifacts from the builder stage
COPY --from=builder /app/dist ./dist
# Prisma client is in node_modules, we already installed production deps

# Security: Create and use a non-root user
RUN addgroup -S nodejs && adduser -S nextjs -G nodejs
RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

# Re-validate that .env is NOT presence in the final image
# (It won't be because of .dockerignore and because we only copy dist)

# Start script
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
