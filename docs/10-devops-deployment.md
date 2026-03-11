# 10. DevOps & Deployment

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield |
| Version | 1.1.0 |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 10.1 CI/CD Pipeline

### Current State
FraudShield currently uses a **manual deployment workflow** with Docker Compose. No automated CI/CD pipeline (GitHub Actions, Jenkins) has been configured.

### Deployment Workflow
```
Developer Machine
    │
    ├── git push origin main
    │
    ▼
Production Server (DigitalOcean Droplet)
    │
    ├── git pull
    ├── docker-compose -f docker-compose.prod.yml build
    ├── docker-compose -f docker-compose.prod.yml up -d
    │
    └── Post-deploy:
        ├── npx prisma migrate deploy (inside container)
        └── Health check: curl http://localhost:3000/health
```

### Recommended CI/CD Pipeline (Not Yet Implemented)
```
Push to main
    │
    ▼
[GitHub Actions / CI]
    │
    ├── Stage 1: Lint & Type Check
    │   ├── npm run lint
    │   ├── tsc --noEmit
    │   └── flutter analyze
    │
    ├── Stage 2: Test
    │   ├── npm test (backend)
    │   └── flutter test (mobile)
    │
    ├── Stage 3: Build
    │   ├── docker build -t fraudshield-api:$SHA .
    │   ├── npm run build (admin)
    │   └── flutter build apk (mobile)
    │
    ├── Stage 4: Push
    │   └── docker push registry/fraudshield-api:$SHA
    │
    └── Stage 5: Deploy
        ├── SSH to production
        ├── docker-compose pull
        └── docker-compose up -d
```

---

## 10.2 Environment Setup

### Development Environment

#### Prerequisites
| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | 20.18+ | Backend runtime |
| npm | 10+ | Package management |
| Docker | 24+ | PostgreSQL, Redis containers |
| Flutter | 3.0+ | Mobile app development |
| Android Studio | Latest | Emulator, SDK tools |
| ADB | Latest | Device communication |

#### Backend Setup
```bash
cd fraudshield-backend
npm install
docker-compose up -d              # PostgreSQL (5432), Redis (6380), pgAdmin (5050)
cp .env.prod.example .env         # Configure environment variables
npx prisma db push                # Push schema to database
npx prisma generate               # Generate Prisma client
npm run dev                       # Start with hot reload (tsx watch)
```

#### Mobile App Setup
```bash
cd fraudshield
flutter pub get
# Start Android emulator
adb reverse tcp:3000 tcp:3000     # Port forward (required per emulator restart)
flutter run
```

#### Admin Dashboard Setup
```bash
cd fraudshield-admin
npm install
npm run dev                       # Vite dev server
```

### Environment Variables (Backend)

#### Required Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@localhost:5432/fraudshield?schema=public&connection_limit=10` |
| `JWT_SECRET` | JWT signing secret (32+ chars) | `<random-hex-64>` |
| `JWT_REFRESH_SECRET` | Refresh token secret (32+ chars) | `<random-hex-64>` |
| `JWT_EXPIRES_IN` | Access token TTL | `15m` |
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment | `development` / `production` |
| `REDIS_PASSWORD` | Redis authentication | `<strong-password>` |
| `SMTP_HOST` | Email server | `smtp.resend.com` |
| `SMTP_PORT` | Email port | `465` |
| `SMTP_USER` | Email user | `resend` |
| `SMTP_PASS` | Email API key | `<api-key>` |
| `SMTP_FROM` | Sender address | `FraudShield <noreply@fraudshieldprotect.com>` |
| `DB_ENCRYPTION_KEY` | AES-256 PII encryption key (32+ chars) | `<random-hex-64>` |

#### Optional Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `REDIS_HOST` | Redis hostname | `localhost` |
| `REDIS_PORT` | Redis port | `6379` |
| `CORS_ORIGIN` | Allowed origins | `*` (dev) |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase Admin JSON | — |
| `OPENAI_API_KEY` | Content moderation API | — |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | — |
| `TURNSTILE_SECRET_KEY` | Cloudflare CAPTCHA secret | — |
| `METRICS_API_KEY` | Prometheus endpoint key | — |
| `TRENDING_ALERT_CRON` | Alert schedule | `0 * * * *` |
| `ADMIN_ALERT_EMAIL` | System alert recipient | — |
| `CRITICAL_ALERT_WEBHOOK_URL` | Discord/Slack webhook | — |
| `ANTI_REPLAY_FAIL_OPEN` | Skip anti-replay on Redis failure | `false` |

### Mobile App Build Variables
```bash
# Release build with environment configuration
flutter build apk \
  --dart-define=API_BASE_URL=https://api.fraudshieldprotect.com/api/v1 \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
```

### Admin Dashboard Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_API_BASE_URL` | Backend API URL | `http://localhost:3000/api/v1` |

---

## 10.3 Infrastructure

### Development Stack (Docker Compose)
```yaml
Services:
  postgres:
    Image: postgres:16-alpine
    Port: 5432
    Volume: postgres_data (persistent)
    Health check: pg_isready

  redis:
    Image: redis:7-alpine
    Port: 6380
    Volume: redis_data (persistent)
    Health check: redis-cli PING
    Auth: password required

  pgadmin:
    Image: dpage/pgadmin4
    Port: 5050
    Optional database GUI
```

### Production Stack (Docker Compose)
```yaml
Services:
  postgres:
    Image: postgres:16.7-alpine
    No external ports (internal only)
    Connection pool: limit=20, timeout=20s
    Volume: postgres_data

  redis:
    Image: redis:7.4-alpine
    No external ports (internal only)
    Auth: password required
    Volume: redis_data

  api:
    Build: ./Dockerfile (multi-stage)
    Port: 3000 (internal)
    Entrypoint: prisma migrate deploy && node dist/server.js
    User: non-root (nextjs)
    Depends on: postgres, redis

  admin:
    Build: ./fraudshield-admin
    Served via Nginx
    Port: 80/443

  db-backup:
    Image: prodrigestivill/postgres-backup-local
    Schedule: 3 AM daily
    Retention: 7 days
    Volume: backups/

  nginx:
    Reverse proxy
    SSL termination
    Rate limiting
    Static file serving
```

### Dockerfile (Multi-Stage Build)
```dockerfile
# Stage 1: Builder
FROM node:20.18-alpine AS builder
RUN apk add python3 make g++
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

# Stage 2: Runner
FROM node:20.18-alpine AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/package.json ./
USER nextjs
EXPOSE 3000
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
```

### Infrastructure Diagram
```
┌──────────────────────────────────────────────────────┐
│                  DigitalOcean Droplet                  │
│                                                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐│
│  │  Nginx   │  │  Docker   │  │  Docker Volumes      ││
│  │  (SSL)   │→ │  Network  │  │  - postgres_data     ││
│  │  :443    │  │           │  │  - redis_data        ││
│  └──────────┘  │  ┌──────┐│  │  - backups/          ││
│       │        │  │ API  ││  └──────────────────────┘│
│       ├───────→│  │:3000 ││                          │
│       │        │  └──┬───┘│                          │
│       │        │     │    │                          │
│       │        │  ┌──┴───┐│  ┌──────────────────┐   │
│       │        │  │Postgres│  │  Backup Service  │   │
│       │        │  │:5432 ││  │  (3 AM daily)    │   │
│       │        │  └──────┘│  └──────────────────┘   │
│       │        │  ┌──────┐│                          │
│       │        │  │Redis ││                          │
│       │        │  │:6379 ││                          │
│       │        │  └──────┘│                          │
│       │        └──────────┘                          │
│       │                                              │
│       ├── Static files (admin dashboard)             │
│       └── Let's Encrypt SSL certificates             │
└──────────────────────────────────────────────────────┘
```

---

## 10.4 Deployment Procedures

### Backend Deployment
```bash
# On production server
cd /app/fraudshield

# Pull latest code
git pull origin main

# Build and deploy
docker-compose -f docker-compose.prod.yml build api
docker-compose -f docker-compose.prod.yml up -d api

# Verify deployment
curl -s http://localhost:3000/health | jq .
# Expected: { "status": "ok" }

curl -s http://localhost:3000/api/v1/status | jq .
# Expected: { "database": "connected", "redis": "connected" }
```

### Database Migration
```bash
# Inside running container
docker exec -it fraudshield-api npx prisma migrate deploy

# Or before starting
npx prisma migrate deploy && node dist/server.js
```

### Rollback Procedure
```bash
# Revert to previous image
docker-compose -f docker-compose.prod.yml stop api
docker tag fraudshield-api:latest fraudshield-api:rollback
docker-compose -f docker-compose.prod.yml up -d api

# If database migration needs rollback
# (manual SQL rollback required — Prisma doesn't support auto-rollback)
```

### Mobile App Release
```bash
cd fraudshield

# Build release APK
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.fraudshieldprotect.com/api/v1 \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com

# Output: build/app/outputs/flutter-apk/app-release.apk
# Upload to Google Play Console
```

---

## 10.5 Backup & Recovery

### Automated Backups
| Component | Schedule | Retention | Method |
|-----------|----------|-----------|--------|
| PostgreSQL | Daily (3 AM) | 7 days | postgres-backup-local container |
| Redis | RDB snapshots | On restart | Redis persistence config |

### Manual Backup
```bash
# Database dump
docker exec fraudshield-postgres pg_dump -U fraudshield fraudshield > backup.sql

# Restore
docker exec -i fraudshield-postgres psql -U fraudshield fraudshield < backup.sql
```

### Disaster Recovery
1. Provision new server
2. Install Docker + Docker Compose
3. Clone repository
4. Restore database from latest backup
5. Configure environment variables
6. Start services with `docker-compose up -d`
7. Verify health endpoints
8. Update DNS records
