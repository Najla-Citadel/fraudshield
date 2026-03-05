# FraudShield

FraudShield is a comprehensive scam detection and prevention platform consisting of a Flutter mobile application and a Node.js backend.

## 🚀 Quick Summary
FraudShield helps users identify and report scams in real-time. It features a mobile dashboard for alerts, scam reporting, and educational resources, all backed by a robust API that manages user data, transactions, and risk assessment.

## 🛠 Tech Stack

### Frontend (Mobile App)
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Networking**: `http`, `flutter_dotenv`
- **Design**: Custom refined design system (Atoms/Molecules)

### Backend (API)
- **Runtime**: [Node.js](https://nodejs.org/) (TypeScript)
- **Framework**: [Express](https://expressjs.com/)
- **Database**: [PostgreSQL](https://www.postgresql.org/) (v16)
- **ORM**: [Prisma](https://www.prisma.io/)
- **Cache/Queue**: [Redis](https://redis.io/)
- **Infras**: [Docker](https://www.docker.com/) & [Docker Compose](https://docs.docker.com/compose/)

### Admin Dashboard (Web)
- **Framework**: [React](https://react.dev/) + [Vite](https://vitejs.dev/)
- **Styling**: [Tailwind CSS](https://tailwindcss.com/)
- **State**: Context API

---

## 💻 Local Setup

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/) (v18+)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Android Studio](https://developer.android.com/studio) (for Emulator)

### 2. Clone the Repository
```bash
git clone https://github.com/Najla-Citadel/fraudshield.git
cd fraudshield
git checkout dev-master
```

### .gitignore (Example for consolidated repo)
```
# Node.js (backend)
fraudshield-backend/node_modules/
fraudshield-backend/dist/
fraudshield-backend/logs/
fraudshield-backend/npm-debug.log*
fraudshield-backend/coverage/
fraudshield-backend/prisma/migrations/*_migration_lock.toml
fraudshield-backend/build/
fraudshield-backend/src/generated/prisma

# Admin Dashboard
fraudshield-admin/node_modules/
fraudshield-admin/dist/
fraudshield-admin/.env

# Flutter (frontend)
fraudshield/.env
fraudshield/.flutter-plugins
fraudshield/.flutter-plugins-dependencies
fraudshield/.dart_tool/
fraudshield/build/
fraudshield/ios/.symlinks/
fraudshield/android/.gradle/
fraudshield/android/local.properties

# Common
.env
.DS_Store
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.vscode/
```

### 3. Backend Setup
1. **Navigate to backend folder**:
   ```bash
   cd fraudshield-backend
   ```
2. **Install dependencies**:
   ```bash
   npm install
   ```
3. **Environment Variables**:
   Copy `.env.example` to `.env` and fill in the secrets (defaults work with Docker).
   Make sure you have a `DATABASE_URL` pointing to the dockerized PostgreSQL container.
4. **Start Database & Redis**:
   Make sure Docker Desktop is running, then execute:
   ```bash
   docker-compose up -d
   ```
5. **Run Migrations**:
   Push the schema to the running database:
   ```bash
   npx prisma db push && npx prisma generate
   ```
6. **Start Backend**:
   Run the backend locally in dev mode:
   ```bash
   npm run dev
   ```
   *The backend should now be running on `http://localhost:3000`.*

### 4. Admin Dashboard Setup
1. **Navigate to admin folder**:
   ```bash
   cd fraudshield-admin
   ```
2. **Install dependencies**:
   ```bash
   npm install
   ```
3. **Start Development Server**:
   ```bash
   npm run dev
   ```
   *The Dashboard should be available on `http://localhost:5173`.*

### 5. Frontend Setup (Mobile App)
1. **Navigate to frontend folder**:
   Open a new terminal and navigate to the flutter project:
   ```bash
   cd fraudshield
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Connect Emulator to Backend**:
   - Open Android Studio or your preferred IDE and launch your **Android Emulator**.
   - Make sure your emulator is fully booted.
   - Run the ADB reverse port forwarding command so the emulator can reach the `localhost:3000` backend on your machine:
   ```bash
   adb reverse tcp:3000 tcp:3000
   ```
   *(Note: You must re-run this command every time you restart your emulator)*
4. **Environment Variables**:
   Ensure `.env` exists in the `fraudshield` folder with:
   ```env
   API_BASE_URL=http://localhost:3000/api/v1
   ```
5. **Run the App**:
   Run the application on the active emulator:
   ```bash
   flutter run
   ```

## 🚢 Deployment

For production deployment instructions using Docker, Nginx, and SSL, see the [DigitalOcean Deployment Guide](deployment_guide.md).

---
 
## 📂 Database Backups
 
FraudShield includes both automated and on-demand backup solutions.
 
### 1. Automated Backups (Production)
The production `docker-compose.prod.yml` includes a `db-backup` sidecar container that automatically dumps the database **every night at 3 AM**.
- **Retention**: Last 7 days.
- **Location**: `fraudshield-backend/backups/`
 
### 2. Manual Backup (On-Demand)
Run the script from the `fraudshield-backend` directory before major updates:
```powershell
./scripts/backup_db.ps1
```
 
### 3. Restoration
To restore a backup to the production container:
```bash
gunzip < backups/db_backup_TIMESTAMP.sql.gz | docker exec -i fraudshield-postgres-prod psql -U fraudshield -d fraudshield
```

---

## 🔒 Security Note
Never commit `.env` files to the repository. They are ignored by default in this consolidated structure.
