# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FraudShield is a monorepo containing:
- **fraudshield-backend/**: Node.js + Express + TypeScript backend API
- **fraudshield/**: Flutter mobile application (Android)
- **fraudshield-admin/**: React admin dashboard (separate from main dev workflow)

## Backend Development

### Environment Setup
```bash
cd fraudshield-backend
npm install
docker-compose up -d              # Start PostgreSQL & Redis
npx prisma db push && npx prisma generate
npm run dev                       # Start backend on http://localhost:3000
```

### Common Backend Commands
```bash
# Development
npm run dev                       # Watch mode with tsx
npm run build                     # Compile TypeScript to dist/
npm start                         # Run compiled code (production)

# Database (Prisma)
npx prisma db push                # Push schema changes to database
npx prisma generate               # Generate Prisma client
npx prisma migrate dev            # Create and apply migration
npx prisma studio                 # Open database GUI

# Testing
npm test                          # Run all tests with Jest
npm run test:watch                # Watch mode
npm run test:coverage             # Generate coverage report

# Code Quality
npm run lint                      # ESLint
npm run format                    # Prettier
```

### Running Individual Tests
```bash
# Run a specific test file
npx jest tests/auth.controller.test.ts

# Run tests matching a pattern
npx jest --testNamePattern="should validate JWT token"
```

## Flutter Mobile App

### Environment Setup
```bash
cd fraudshield
flutter pub get
# Start Android emulator, then:
adb reverse tcp:3000 tcp:3000    # Forward backend port (re-run after emulator restart)
flutter run
```

### Common Flutter Commands
```bash
flutter run                       # Run app on connected device/emulator
flutter run -d <device-id>        # Run on specific device
flutter build apk                 # Build APK
flutter test                      # Run tests
flutter clean                     # Clean build cache
flutter pub get                   # Install dependencies
flutter pub outdated              # Check for updates
```

### Critical: ADB Port Forwarding
The emulator needs port forwarding to access `localhost:3000` backend:
```bash
adb reverse tcp:3000 tcp:3000
```
This must be re-run **every time** you restart the emulator.

## Architecture

### Backend Architecture (MVC + Services Pattern)

#### Request Flow
```
Request → Middleware (auth, rate limit, metrics) → Route → Controller → Service → Database/External API
```

#### Key Patterns
- **Routes** (`src/routes/*.routes.ts`): Express routers defining endpoints
- **Controllers** (`src/controllers/*.controller.ts`): Handle HTTP requests/responses, validation
- **Services** (`src/services/*.service.ts`): Business logic, database operations, external API calls
- **Middleware** (`src/middleware/*.middleware.ts`): Authentication, rate limiting, request tracing, metrics
- **Config** (`src/config/*.ts`): Database (Prisma), Redis, Passport JWT, Firebase, environment validation

#### Critical Middleware Stack (app.ts)
Applied in this order:
1. `tracer` - Adds correlation ID to all requests
2. `metricsMiddleware` - APM/performance monitoring
3. `requestTimeout` - 30s global timeout
4. `antiReplay` - Timestamp + nonce validation for security
5. `helmet` - Security headers
6. `passport` - JWT authentication

#### Database Layer
- **ORM**: Prisma Client (`@prisma/client`)
- **Schema**: `fraudshield-backend/prisma/schema.prisma`
- **Connection**: Singleton pattern via `src/config/database.ts` exports `prisma` client
- Models include: User, ScamReport, Alert, Transaction, Profile, SecurityScan, etc.

#### Background Jobs & Real-time
- **Socket.io**: Real-time communication (initialized in `src/server.ts`, exported as `io`)
- **Bull Queue**: Background job processing (AlertWorkerService)
- **Redis**: Used for caching, rate limiting, and Bull queues

#### Security Features
- **App Attestation**: Google Play Integrity API (`src/services/attestation.service.ts`)
- **Anti-Replay Protection**: Nonce-based request deduplication (`src/middleware/antiReplay.middleware.ts`)
- **Rate Limiting**: Redis-backed rate limiting (`src/middleware/rateLimiter.ts`)
- **Audit Logging**: All admin actions logged (`src/services/audit.service.ts`)

### Frontend Architecture (Flutter Provider Pattern)

#### State Management
Uses Provider pattern with `ChangeNotifierProvider`:
- **AuthProvider**: User authentication state, subscription status
- **ThemeProvider**: Light/dark mode
- **LocaleProvider**: Internationalization (en/ms)
- **NotificationService**: Global notification state, overlay management

#### Key Services (Singletons)
- `AttestationService`: App integrity verification
- `CallStateService`: Phone call monitoring (Phase 2 feature)
- `ClipboardMonitorService`: Clipboard monitoring for scam detection
- `SecurityService`: Jailbreak/root detection, app tampering checks
- `NotificationService`: FCM, local notifications, overlay management
- `ScamScannerService`: Multi-modal scam detection (URL, voice, PDF, APK)

#### Navigation
- Centralized routing via `app_router.dart`
- Uses `AppRouter.navigatorKey` for programmatic navigation
- Root navigation handled by `RootScreen` (bottom nav + screen management)

#### Design System
- **Location**: `lib/design_system/`
- **Tokens**: `design_tokens.dart`, `typography.dart`
- **Components**: Reusable UI components (buttons, skeletons, dialogs)
- **Layouts**: `screen_scaffold.dart` for consistent screen structure

#### Firebase Integration
- **Crashlytics**: Error reporting configured in `main.dart`
- **Messaging**: FCM push notifications
- **Auth**: Google Sign-In integration

#### Phase 2 Features (Real-time Protection)
- **Foreground Service**: Background call monitoring (`flutter_foreground_task`)
- **Overlay System**: System-wide caller risk overlays (`flutter_overlay_window`)
- Entry point: `overlayMain()` in `main.dart`
- **Call Protection**: Real-time scam caller detection during active calls

## Docker Infrastructure

### Development
```bash
# From fraudshield-backend/
docker-compose up -d              # PostgreSQL (5432), Redis (6380), pgAdmin (5050)
docker-compose down               # Stop all services
docker-compose logs postgres      # View logs
```

### Production
Uses `docker-compose.prod.yml` with automated database backups (3 AM daily).

## API Documentation

Swagger UI available in development mode:
- http://localhost:3000/api-docs
- http://localhost:3000/api/v1/docs

## Testing Strategy

### Backend Tests
- **Framework**: Jest + ts-jest
- **Location**: `fraudshield-backend/tests/`
- **Patterns**: Unit tests for services, integration tests in `tests/integration/`
- **Mocking**: Prisma client mocked for unit tests
- Tests run sequentially (`--runInBand`) to avoid database conflicts

### Flutter Tests
- **Location**: `fraudshield/test/`
- Widget tests and unit tests using Flutter's built-in test framework

## Important Notes

### Security Practices
- Never commit `.env` files (already in `.gitignore`)
- API keys stored in environment variables (validated via `src/config/env.ts`)
- Certificate pinning enabled in Flutter app (`http_certificate_pinning`)
- All admin actions audited via `AuditLog` model

### Database Migrations
Use `npx prisma db push` for development. For production:
```bash
npx prisma migrate dev --name descriptive_name
```

### Git Workflow
- Main branch: `main`
- Use `dev-master` for development features
- Backend and frontend changes can be committed together (monorepo)

### Common Gotchas
1. Emulator must have `adb reverse tcp:3000 tcp:3000` run after each restart
2. Prisma schema changes require `npx prisma generate` to update client types
3. Redis password required for connections (set via `REDIS_INIT_PASSWORD` in `.env`)
4. Socket.io instance exported from `server.ts`, not `app.ts`
5. Anti-replay middleware requires `X-Request-Timestamp` and `X-Request-Nonce` headers for protected endpoints
