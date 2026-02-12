-- AlterTable
ALTER TABLE "Profile" ADD COLUMN     "badges" JSONB NOT NULL DEFAULT '[]',
ADD COLUMN     "reputation" INTEGER NOT NULL DEFAULT 0;
