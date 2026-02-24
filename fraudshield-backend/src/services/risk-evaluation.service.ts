import { prisma } from '../config/database';

export interface RiskFactor {
    key: string;
    weight: number;
    description: string;
}

export interface RiskEvaluationResult {
    score: number;         // 0–100
    level: 'low' | 'medium' | 'high' | 'critical';
    reasons: string[];
    factors: {
        communityReports: number;
        verifiedReports: number;
        avgReporterReputation: number;
        recencyScore: number;       // Higher = more recent activity
        verificationRatio: number;  // % of people who agreed it's a scam
    };
    checkedAt: string;
}

export class RiskEvaluationService {
    // ── Weight Configuration  ─────────────────────────────────────────────
    // These weights sum to 1.0. Adjust as you gather more real-world data.
    // This is the "formula" that ML will eventually replace.
    private static readonly W_COMMUNITY_REPORTS = 0.35;
    private static readonly W_VERIFICATION_RATIO = 0.30;
    private static readonly W_REPORTER_REP = 0.20;
    private static readonly W_RECENCY = 0.15;

    /**
     * Primary entry point. Evaluates risk for any target and type.
     * type: 'phone' | 'bank' | 'url' | 'doc'
     */
    static async evaluate(type: string, value: string): Promise<RiskEvaluationResult> {
        const cleanValue = value.trim().toLowerCase();

        // 1. Query community intelligence from DB
        const communityData = await this.getCommunityIntelligence(type, cleanValue);

        // 2. Build each sub-score (0–100)
        const communityScore = this.calcCommunityScore(communityData.totalReports);
        const verRatioScore = this.calcVerificationRatioScore(communityData.verifiedReports, communityData.totalReports);
        const repScore = this.calcReputationScore(communityData.avgReporterReputation);
        const recencyScore = this.calcRecencyScore(communityData.daysSinceLastReport);

        // 3. Weighted composite score
        const rawScore =
            communityScore * this.W_COMMUNITY_REPORTS +
            verRatioScore * this.W_VERIFICATION_RATIO +
            repScore * this.W_REPORTER_REP +
            recencyScore * this.W_RECENCY;

        const score = Math.round(Math.min(rawScore, 100));

        // 4. Determine level
        const level = this.getLevel(score);

        // 5. Build human-readable reasons
        const reasons = this.buildReasons({
            score,
            communityData,
            communityScore,
            verRatioScore,
            repScore,
            recencyScore,
        });

        return {
            score,
            level,
            reasons,
            factors: {
                communityReports: communityData.totalReports,
                verifiedReports: communityData.verifiedReports,
                avgReporterReputation: communityData.avgReporterReputation,
                recencyScore: Math.round(recencyScore),
                verificationRatio: communityData.totalReports > 0
                    ? Math.round((communityData.verifiedReports / communityData.totalReports) * 100)
                    : 0,
            },
            checkedAt: new Date().toISOString(),
        };
    }

    // ── DB Query ──────────────────────────────────────────────────────────

    private static async getCommunityIntelligence(type: string, value: string) {
        let whereClause: any = { isPublic: true };

        // Map Flutter type strings to db values
        if (type === 'phone' || type === 'bank') {
            whereClause.targetType = type === 'phone' ? 'phone' : 'bank_account';
            whereClause.target = { contains: value, mode: 'insensitive' };
        } else if (type === 'url') {
            whereClause.targetType = 'url';
            whereClause.target = { contains: value, mode: 'insensitive' };
        }

        const reports = await prisma.scamReport.findMany({
            where: whereClause,
            include: {
                verifications: true,
                user: {
                    include: { profile: true }
                }
            },
            orderBy: { createdAt: 'desc' },
            take: 50, // Cap for performance
        });

        const totalReports = reports.length;
        let verifiedReports = 0;
        let totalReputation = 0;
        let latestDate: Date | null = null;

        for (const report of reports) {
            // Count verifications where majority agreed it IS a scam
            const positiveVerifications = report.verifications.filter(v => v.isSame).length;
            if (positiveVerifications > 0) verifiedReports++;

            // Sum up reputation of reporters (weight trusted reporters higher)
            const rep = report.user?.profile?.reputation ?? 0;
            totalReputation += rep;

            if (!latestDate || report.createdAt > latestDate) {
                latestDate = report.createdAt;
            }
        }

        const avgReporterReputation = totalReports > 0 ? totalReputation / totalReports : 0;
        const daysSinceLastReport = latestDate
            ? (Date.now() - latestDate.getTime()) / (1000 * 60 * 60 * 24)
            : 999; // No reports = old

        return { totalReports, verifiedReports, avgReporterReputation, daysSinceLastReport };
    }

    // ── Sub-scorers ───────────────────────────────────────────────────────

    /** Maps report count to a 0–100 score using a logarithmic curve */
    private static calcCommunityScore(totalReports: number): number {
        if (totalReports === 0) return 0;
        // log2 curve: 1 report = 10, 2 = 20, 4 = 30, 8 = 40, 16 = 50 ... caps at ~100
        return Math.min(10 * Math.log2(totalReports + 1) * 3, 100);
    }

    /** % of reports that got verified as scam (0–100) */
    private static calcVerificationRatioScore(verified: number, total: number): number {
        if (total === 0) return 0;
        return (verified / total) * 100;
    }

    /** Scales reporter reputation (average) to a 0–100 score */
    private static calcReputationScore(avgRep: number): number {
        // Assume max reputation in system = 200
        return Math.min((avgRep / 200) * 100, 100);
    }

    /** More recent = higher risk score. Old reports decay. */
    private static calcRecencyScore(daysSince: number): number {
        if (daysSince >= 999) return 0;    // No reports yet
        if (daysSince <= 1) return 100;   // Within 24 hours
        if (daysSince <= 7) return 80;    // Within a week
        if (daysSince <= 30) return 50;   // Within a month
        if (daysSince <= 90) return 30;   // Within 3 months
        return 10;                         // Very old
    }

    // ── Level ─────────────────────────────────────────────────────────────

    private static getLevel(score: number): 'low' | 'medium' | 'high' | 'critical' {
        if (score >= 80) return 'critical';
        if (score >= 55) return 'high';
        if (score >= 30) return 'medium';
        return 'low';
    }

    // ── Reasons Builder ───────────────────────────────────────────────────

    private static buildReasons(data: {
        score: number;
        communityData: Awaited<ReturnType<typeof RiskEvaluationService.getCommunityIntelligence>>;
        communityScore: number;
        verRatioScore: number;
        repScore: number;
        recencyScore: number;
    }): string[] {
        const { communityData } = data;
        const reasons: string[] = [];

        if (communityData.totalReports === 0) {
            reasons.push('✅ No community reports found for this target');
            return reasons;
        }

        if (communityData.totalReports >= 10) {
            reasons.push(`🚨 Widely reported: ${communityData.totalReports} reports in the community`);
        } else if (communityData.totalReports >= 3) {
            reasons.push(`⚠️ Multiple community reports: ${communityData.totalReports} reports found`);
        } else {
            reasons.push(`📋 ${communityData.totalReports} community report(s) found`);
        }

        if (communityData.verifiedReports > 0) {
            reasons.push(`👥 Verified by ${communityData.verifiedReports} community member(s)`);
        }

        if (communityData.avgReporterReputation >= 50) {
            reasons.push(`🎖️ Reported by high-reputation community members`);
        }

        if (data.recencyScore >= 80) {
            reasons.push(`🕐 Very recently reported (within 1 week)`);
        } else if (data.recencyScore >= 50) {
            reasons.push(`🕐 Reported within the last month`);
        }

        return reasons;
    }
}
