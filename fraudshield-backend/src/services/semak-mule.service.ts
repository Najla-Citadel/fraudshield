// ─────────────────────────────────────────────────────────────────────────────
// SemakMuleService — PDRM CCID Semak Mule Integration Gate
// ─────────────────────────────────────────────────────────────────────────────
//
// STATUS: MOCK / PENDING API ACCESS
//
// The RiskEvaluationService is fully wired to call this service for every
// 'phone' and 'bank' check.  No other file needs to change when the real
// API becomes available — only the `checkTarget` method below.
//
// TODO: Replace the mock implementation with the real PDRM CCID Semak Mule API
//       once a formal data-access agreement has been signed.
//
// INTEGRATION CHECKLIST (when API access is obtained):
//   [ ] 1. Store the API endpoint + credentials in .env
//           SEMAK_MULE_API_URL=https://...
//           SEMAK_MULE_API_KEY=...
//   [ ] 2. Replace the mock body below with an actual HTTPS call:
//           const res = await fetch(`${process.env.SEMAK_MULE_API_URL}/check`, {
//               method: 'POST',
//               headers: { 'Authorization': `Bearer ${process.env.SEMAK_MULE_API_KEY}` },
//               body: JSON.stringify({ type, value }),
//           });
//           const data = await res.json();
//   [ ] 3. Map the API response fields to the return shape below.
//   [ ] 4. Remove the artificial `setTimeout` delay.
//   [ ] 5. Add error handling / circuit-breaker so a Semak Mule outage
//          degrades gracefully (fall through with semakMuleData = null).
//
// The rest of the scoring pipeline (RiskEvaluationService) already handles
// a null semakMuleData gracefully — zero changes required there.
// ─────────────────────────────────────────────────────────────────────────────

export class SemakMuleService {
    /**
     * ⚠️  MOCK IMPLEMENTATION — awaiting API agreement with PDRM CCID.
     *
     * When the real Semak Mule API is available, replace this method body
     * with the actual HTTP call (see the integration checklist above).
     *
     * Current mock logic:
     *   - Ends with "000" or "999" → HIGH risk  (simulates a blacklisted number)
     *   - Anything else            → LOW risk   (simulates a clean lookup)
     */
    static async checkTarget(type: 'phone' | 'bank', value: string): Promise<{
        found: boolean;
        riskLevel: 'high' | 'low';
        reportsCount: number;
        recommendation: string;
    }> {
        // ── TODO: replace block below with real API call ──────────────────────
        // Simulate network latency of the real endpoint
        await new Promise(resolve => setTimeout(resolve, 800));

        const isBlacklisted = value.endsWith('000') || value.endsWith('999');

        if (isBlacklisted) {
            return {
                found: true,
                riskLevel: 'high',
                reportsCount: Math.floor(Math.random() * 15) + 3, // mock 3–17 reports
                recommendation: `This ${type} is listed in the official PDRM Semak Mule database as fraudulent. Do NOT proceed with any transactions.`,
            };
        }

        return {
            found: false,
            riskLevel: 'low',
            reportsCount: 0,
            recommendation: `This ${type} is not listed in the official PDRM Semak Mule database, but please remain vigilant.`,
        };
        // ── end TODO block ────────────────────────────────────────────────────
    }
}
