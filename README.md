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
4. **Start Database & Redis**:
   ```bash
   docker-compose up -d
   ```
5. **Run Migrations**:
   ```bash
   npx prisma migrate dev
   ```
6. **Start Backend**:
   ```bash
   npm run dev
   ```

### 4. Frontend Setup
1. **Navigate to frontend folder**:
   ```bash
   cd ../fraudshield
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Environment Variables**:
   Ensure `.env` exists with:
   ```env
   API_BASE_URL=http://localhost:3000/api/v1
   ```
4. **Connect Emulator to Backend**:
   Since the app runs in an emulator, you must bridge the networking:
   ```bash
   adb reverse tcp:3000 tcp:3000
   ```
5. **Run the App**:
   ```bash
   flutter run
   ```

---

## 🔒 Security Note
Never commit `.env` files to the repository. They are ignored by default in this consolidated structure.
