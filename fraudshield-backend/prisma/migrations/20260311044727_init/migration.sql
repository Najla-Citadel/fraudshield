/*
  Warnings:

  - A unique constraint covering the columns `[refreshToken]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[reportId,userId]` on the table `Verification` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "CheckType" AS ENUM ('PHONE', 'URL', 'BANK', 'DOC', 'MANUAL', 'MSG', 'QR', 'VOICE', 'MACAU_SCAM', 'MULE', 'AUTO_CAPTURE');

-- CreateEnum
CREATE TYPE "AlertSeverity" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');

-- CreateEnum
CREATE TYPE "AlertCategory" AS ENUM ('PHISHING', 'LOGIN', 'SYSTEM_SCAN', 'NETWORK', 'COMMUNITY', 'MACAU_SCAM', 'MULE_ACCOUNT');

-- AlterTable
ALTER TABLE "Alert" ADD COLUMN     "actionTaken" TEXT,
ADD COLUMN     "category" "AlertCategory" NOT NULL DEFAULT 'COMMUNITY',
ADD COLUMN     "metadata" JSONB NOT NULL DEFAULT '{}',
ADD COLUMN     "severity" "AlertSeverity" NOT NULL DEFAULT 'LOW',
ALTER COLUMN "type" SET DEFAULT 'ALERT';

-- AlterTable
ALTER TABLE "Profile" ADD COLUMN     "lastLoginDate" TIMESTAMP(3),
ADD COLUMN     "loginStreak" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "mailingAddress" TEXT,
ADD COLUMN     "mobile" TEXT,
ADD COLUMN     "preferredName" TEXT,
ADD COLUMN     "totalPoints" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "Reward" ADD COLUMN     "isFeatured" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "minTier" TEXT NOT NULL DEFAULT 'BRONZE';

-- AlterTable
ALTER TABLE "ScamReport" ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "targetType" TEXT;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "acceptedTermsAt" TIMESTAMP(3),
ADD COLUMN     "acceptedTermsVersion" TEXT,
ADD COLUMN     "emailVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "refreshToken" TEXT;

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "adminId" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "targetType" TEXT NOT NULL,
    "targetId" TEXT,
    "payload" JSONB NOT NULL DEFAULT '{}',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Comment" (
    "id" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "reportId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Comment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SecurityScan" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "totalAppsScanned" INTEGER NOT NULL,
    "riskyApps" JSONB NOT NULL DEFAULT '[]',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SecurityScan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AppReputation" (
    "packageName" TEXT NOT NULL,
    "safeVotes" INTEGER NOT NULL DEFAULT 0,
    "threatReports" INTEGER NOT NULL DEFAULT 0,
    "globalScoreAdjustment" INTEGER NOT NULL DEFAULT 0,
    "lastUpdated" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AppReputation_pkey" PRIMARY KEY ("packageName")
);

-- CreateTable
CREATE TABLE "AppActionLog" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "packageName" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AppActionLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BadgeDefinition" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "icon" TEXT NOT NULL,
    "tier" TEXT NOT NULL,
    "trigger" TEXT NOT NULL,
    "threshold" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BadgeDefinition_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TransactionJournal" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "checkType" "CheckType" NOT NULL,
    "target" TEXT,
    "riskScore" INTEGER NOT NULL,
    "status" TEXT NOT NULL,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "amount" DOUBLE PRECISION,
    "merchant" TEXT,
    "notes" TEXT,
    "paymentMethod" TEXT,
    "platform" TEXT,
    "reportId" TEXT,

    CONSTRAINT "TransactionJournal_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AlertSubscription" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "categories" TEXT[],
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "radiusKm" INTEGER NOT NULL DEFAULT 15,
    "fcmToken" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "emailDigestEnabled" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "AlertSubscription_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AuditLog_adminId_idx" ON "AuditLog"("adminId");

-- CreateIndex
CREATE INDEX "AuditLog_createdAt_idx" ON "AuditLog"("createdAt");

-- CreateIndex
CREATE INDEX "AuditLog_action_idx" ON "AuditLog"("action");

-- CreateIndex
CREATE INDEX "AuditLog_targetType_idx" ON "AuditLog"("targetType");

-- CreateIndex
CREATE INDEX "Comment_reportId_idx" ON "Comment"("reportId");

-- CreateIndex
CREATE INDEX "SecurityScan_userId_idx" ON "SecurityScan"("userId");

-- CreateIndex
CREATE INDEX "SecurityScan_createdAt_idx" ON "SecurityScan"("createdAt");

-- CreateIndex
CREATE INDEX "AppReputation_packageName_idx" ON "AppReputation"("packageName");

-- CreateIndex
CREATE INDEX "AppActionLog_packageName_idx" ON "AppActionLog"("packageName");

-- CreateIndex
CREATE UNIQUE INDEX "AppActionLog_userId_packageName_action_key" ON "AppActionLog"("userId", "packageName", "action");

-- CreateIndex
CREATE UNIQUE INDEX "BadgeDefinition_key_key" ON "BadgeDefinition"("key");

-- CreateIndex
CREATE INDEX "TransactionJournal_userId_idx" ON "TransactionJournal"("userId");

-- CreateIndex
CREATE INDEX "TransactionJournal_createdAt_idx" ON "TransactionJournal"("createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "AlertSubscription_userId_key" ON "AlertSubscription"("userId");

-- CreateIndex
CREATE INDEX "ScamReport_isPublic_idx" ON "ScamReport"("isPublic");

-- CreateIndex
CREATE INDEX "ScamReport_createdAt_idx" ON "ScamReport"("createdAt");

-- CreateIndex
CREATE INDEX "ScamReport_category_idx" ON "ScamReport"("category");

-- CreateIndex
CREATE INDEX "ScamReport_status_idx" ON "ScamReport"("status");

-- CreateIndex
CREATE INDEX "ScamReport_target_idx" ON "ScamReport"("target");

-- CreateIndex
CREATE INDEX "ScamReport_targetType_idx" ON "ScamReport"("targetType");

-- CreateIndex
CREATE UNIQUE INDEX "User_refreshToken_key" ON "User"("refreshToken");

-- CreateIndex
CREATE UNIQUE INDEX "Verification_reportId_userId_key" ON "Verification"("reportId", "userId");

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_adminId_fkey" FOREIGN KEY ("adminId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Comment" ADD CONSTRAINT "Comment_reportId_fkey" FOREIGN KEY ("reportId") REFERENCES "ScamReport"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Comment" ADD CONSTRAINT "Comment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SecurityScan" ADD CONSTRAINT "SecurityScan_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TransactionJournal" ADD CONSTRAINT "TransactionJournal_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AlertSubscription" ADD CONSTRAINT "AlertSubscription_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
