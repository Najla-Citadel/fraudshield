import { prisma } from '../config/database';
import { NlpMessageService } from './nlp-message.service';
import { EncryptionUtils } from '../utils/encryption';
import { getRedisClient } from '../config/redis';

export interface MacauScamSignal {
    type: 'content' | 'transaction' | 'voice';
    description: string;
    severity: 'MEDIUM' | 'HIGH' | 'CRITICAL';
}

export interface MacauScamEvaluation {
    isMacauScam: boolean;
    confidence: 'low' | 'medium' | 'high' | 'critical';
    riskScore: number;
    signals: MacauScamSignal[];
    recommendation: string;
    emergencyContacts: { name: string; number: string }[];
}

export class MacauScamService {
    /**
     * Combined risk assessment for a user's action/message
     */
    static async evaluate(userId: string, text?: string, txId?: string): Promise<MacauScamEvaluation> {
        const signals: MacauScamSignal[] = [];
        let totalScore = 0;

        // 1. Content Analysis (if text provided)
        if (text) {
            const nlpResult = NlpMessageService.analyze(text);
            if (nlpResult.scamType === 'macau_scam') {
                signals.push({
                    type: 'content',
                    description: `Macau Scam narrative detected: ${nlpResult.matchedPatterns.join(', ')}`,
                    severity: nlpResult.level === 'critical' ? 'CRITICAL' : 'HIGH'
                });
                totalScore += nlpResult.score;
            }
        }

        // 2. Transaction Pattern Analysis (if txId provided)
        if (txId) {
            const tx = await prisma.transactionJournal.findUnique({ where: { id: txId } });
            if (tx) {
                // Feature: New Beneficiary Detection
                const encryptedTarget = tx.target;
                const previousTxs = await prisma.transactionJournal.count({
                    where: {
                        userId,
                        target: encryptedTarget,
                        id: { not: txId },
                        status: 'SAFE'
                    }
                });

                if (previousTxs === 0 && (tx.amount || 0) >= 1000) {
                    signals.push({
                        type: 'transaction',
                        description: 'First-time transfer to this recipient with high amount (RM 1,000+)',
                        severity: 'HIGH'
                    });
                    totalScore += 40;
                }

                // Feature: Rapid Successive Transfers
                const recentTxs = await prisma.transactionJournal.count({
                    where: {
                        userId,
                        createdAt: { gte: new Date(Date.now() - 30 * 60 * 1000) }, // last 30 mins
                        id: { not: txId }
                    }
                });
                if (recentTxs >= 2) {
                    signals.push({
                        type: 'transaction',
                        description: 'Multiple transfers initiated in a short period (possible pressure tactic)',
                        severity: 'MEDIUM'
                    });
                    totalScore += 20;
                }
            }
        }

        // 3. Voice Context Analysis (Redis-backed correlation)
        try {
            const redis = getRedisClient();
            const voiceSignal = await redis.get(`macau_signal:voice:${userId}`);
            if (voiceSignal) {
                signals.push({
                    type: 'voice',
                    description: 'Transaction/Message follows a recent suspicious call from a purported authority',
                    severity: 'HIGH'
                });
                totalScore += 30;
            }
        } catch (e) { /* ignore redis error */ }

        const finalScore = Math.min(totalScore, 100);
        const isMacauScam = finalScore >= 50;
        const confidence = this._getConfidence(finalScore);

        return {
            isMacauScam,
            confidence,
            riskScore: finalScore,
            signals,
            recommendation: this._getRecommendation(finalScore),
            emergencyContacts: [
                { name: 'NSRC Cyber997', number: '997' },
                { name: 'PDRM CCID Scam Response', number: '03-2610 1559' },
                { name: 'BNM TELELINK', number: '1-300-88-5465' }
            ]
        };
    }

    private static _getConfidence(score: number): 'low' | 'medium' | 'high' | 'critical' {
        if (score >= 80) return 'critical';
        if (score >= 60) return 'high';
        if (score >= 40) return 'medium';
        return 'low';
    }

    private static _getRecommendation(score: number): string {
        if (score >= 70) {
            return '🚨 CRITICAL: High Macau Scam probability. DO NOT transfer money. Authorities will NEVER ask you to move funds to a "safe account". Contact NSRC 997 immediately.';
        }
        if (score >= 40) {
            return '⚠️ WARNING: Suspicious Macau Scam indicators found. Verify any "official" claims by calling the agency back using numbers from their official website. Do not use numbers provided by the caller.';
        }
        return 'Proceed with caution. Always verify the identity of unknown callers claiming to be from government agencies.';
    }
}
