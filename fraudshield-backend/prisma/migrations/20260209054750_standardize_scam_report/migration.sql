/*
  Warnings:

  - You are about to drop the column `evidenceUrl` on the `ScamReport` table. All the data in the column will be lost.
  - Added the required column `category` to the `ScamReport` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "ScamReport" DROP COLUMN "evidenceUrl",
ADD COLUMN     "category" TEXT NOT NULL,
ADD COLUMN     "evidence" JSONB NOT NULL DEFAULT '{}',
ALTER COLUMN "target" DROP NOT NULL;
