export class SemakMuleService {
    /**
     * Mocks a call to the PDRM CCID Semak Mule API.
     * In a real-world scenario, this would make an HTTPS request to the official portal
     * and parse the response to determine if the phone/account is blacklisted.
     * 
     * For this mock:
     * - Returns HIGH risk if the last 3 digits are "000" or "999" (common scam mockup values)
     * - Returns LOW risk otherwise.
     */
    static async checkTarget(type: 'phone' | 'bank', value: string): Promise<{
        found: boolean;
        riskLevel: 'high' | 'low';
        reportsCount: number;
        recommendation: string;
    }> {
        // Simulate network delay
        await new Promise(resolve => setTimeout(resolve, 800));

        const isBlacklisted = value.endsWith('000') || value.endsWith('999');

        if (isBlacklisted) {
            return {
                found: true,
                riskLevel: 'high',
                reportsCount: Math.floor(Math.random() * 15) + 3, // Mock 3-17 reports
                recommendation: `This ${type} is listed in the official PDRM Semak Mule database as fraudulent. Do NOT proceed with any transactions.`,
            };
        }

        return {
            found: false,
            riskLevel: 'low',
            reportsCount: 0,
            recommendation: `This ${type} is not listed in the official PDRM Semak Mule database, but please remain vigilant.`,
        };
    }
}
