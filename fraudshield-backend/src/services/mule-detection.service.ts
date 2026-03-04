import { prisma } from '../config/database';
import logger from '../utils/logger';

export interface MuleRiskResult {
    isMule: boolean;
    riskScore: number;
    triggeredRules: string[];
    recommendation: string;
    confidence: 'low' | 'medium' | 'high' | 'critical';
}

export class MuleDetectionService {
    /**
     * Evaluate a transaction for Mule Account activity (Velocity Rules)
     * Rule 1: Rapid Credit-Then-Debit (Funds in and out within 30 mins)
     * Rule 2: Fan-In Pattern (>=3 transactions from different sources in 24h)
     * Rule 3: Sudden Volume Spike (>5x 30-day average)
     */
    static async evaluate(
        userId: string,
        amount: number | null,
        target: string | null
    ): Promise<MuleRiskResult> {
        const result: MuleRiskResult = {
            isMule: false,
            riskScore: 0,
            triggeredRules: [],
            recommendation: 'No mule activity detected.',
            confidence: 'low'
        };

        if (!amount || amount === 0) {
            return result;
        }

        const now = new Date();
        const thirtyMinsAgo = new Date(now.getTime() - 30 * 60 * 1000);
        const twentyFourHoursAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

        // Fetch recent transactions for evaluation
        const recentTransactions = await prisma.transactionJournal.findMany({
            where: {
                userId,
                createdAt: { gte: thirtyDaysAgo }
            },
            orderBy: { createdAt: 'desc' }
        });

        if (recentTransactions.length === 0) {
            return result;
        }

        // --- Rule 1: Rapid Credit-Then-Debit (Last 30 mins) ---
        const last30MinsTx = recentTransactions.filter(tx => tx.createdAt >= thirtyMinsAgo);
        if (last30MinsTx.length >= 2) {
            // Check if there are multiple transactions in a very short span
            // This is a proxy for rapid pass-through of funds
            result.isMule = true;
            result.triggeredRules.push('Rapid Pass-Through');
            result.riskScore += 50;
        }

        // --- Rule 2: Fan-In Pattern (Last 24 hours) ---
        const last24hTx = recentTransactions.filter(tx => tx.createdAt >= twentyFourHoursAgo);
        const distinctSources = new Set(
            last24hTx.map(tx => tx.target || tx.merchant || 'Unknown')
        );

        if (distinctSources.size >= 3 && last24hTx.length >= 3) {
            result.isMule = true;
            result.triggeredRules.push('Fan-In Pattern');
            result.riskScore += 40;
        }

        // --- Rule 3: Sudden Volume Spike ---
        // Calculate daily average over the past 30 days (excluding today)
        const olderTx = recentTransactions.filter(tx => tx.createdAt < twentyFourHoursAgo);
        let olderTotalVolume = 0;
        olderTx.forEach(tx => {
            olderTotalVolume += Math.abs(tx.amount || 0);
        });
        const dailyAverage = olderTotalVolume / 30;

        // Calculate today's volume (last 24 hours)
        let todayVolume = Math.abs(amount - 0); // Include the current transaction
        last24hTx.forEach(tx => {
            todayVolume += Math.abs(tx.amount || 0);
        });

        // Trigger if today's volume is > 5x the average, and average is meaningful (e.g. > 100)
        // Or if it's a completely new account spiking over 5000 immediately
        if ((dailyAverage > 100 && todayVolume > dailyAverage * 5) || (olderTx.length === 0 && todayVolume > 5000)) {
            result.isMule = true;
            result.triggeredRules.push('Sudden Volume Spike');
            result.riskScore += 30;
        }

        // Finalize results
        if (result.isMule) {
            result.riskScore = Math.min(result.riskScore, 100);

            if (result.riskScore >= 80) {
                result.confidence = 'critical';
                result.recommendation = 'CRITICAL: Account exhibits strong money mule patterns. Transactions blocked pending BNM STR filing.';
            } else if (result.riskScore >= 50) {
                result.confidence = 'high';
                result.recommendation = 'HIGH RISK: Unusual velocity detected. Please verify your recent funds transfers immediately.';
            } else {
                result.confidence = 'medium';
                result.recommendation = 'WARNING: Transaction patterns show slight deviations from normal behavior.';
            }

            logger.warn(`MuleDetectionService: Detected Mule Activity for User ${userId}. Risk Score: ${result.riskScore}. Rules triggered: ${result.triggeredRules.join(', ')}`);
        }

        return result;
    }
}
