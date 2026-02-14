FROM node:20-alpine

WORKDIR /app

# Install dependencies first for caching
COPY package*.json ./
COPY prisma ./prisma/

# Install build dependencies for native modules (like bcrypt)
RUN apk add --no-cache python3 make g++

RUN npm install
RUN npx prisma generate

# Copy source and build
COPY . .
RUN npm run build

EXPOSE 3000

# Start script should run migrations then start server
# Usually better to run migrations in a separate step, but for staging this is simpler
CMD ["sh", "-c", "npx prisma migrate deploy && npm start"]
