export type ScamType =
    | 'phishing'
    | 'investment'
    | 'impersonation'
    | 'lottery'
    | 'romance'
    | 'delivery'
    | 'tech_support'
    | null;

export type Language = 'en' | 'ms' | 'zh' | 'mixed';

export interface MessageAnalysisResult {
    score: number;
    level: 'low' | 'medium' | 'high' | 'critical';
    scamType: ScamType;
    language: Language;
    matchedPatterns: string[];
    highlightedPhrases: string[];
    checkedAt: string;
}

// ── Pattern Dictionaries ────────────────────────────────────────────────────

/** High-confidence scam phrases — matched case-insensitively */
const SCAM_PHRASES: Array<{ pattern: RegExp; label: string; score: number; type: ScamType }> = [
    // ── PHISHING (EN) ──
    { pattern: /your (account|bank|card).{0,30}(has been |is |will be |becomes |was )?(suspended|blocked|restricted|frozen|compromised|dikemaskini|disekat)/i, label: 'Account status threat', score: 60, type: 'phishing' },
    { pattern: /click.{1,20}(here|the link|below|this link).{1,50}(verify|confirm|update|restore|unlock|claim)/i, label: 'Phishing link prompt', score: 50, type: 'phishing' },
    { pattern: /your.{1,20}(otp|one.time.pass(word|code)|pin|password|credential)/i, label: 'Credential solicitation', score: 65, type: 'phishing' },
    { pattern: /enter.{1,20}(details|password|pin|otp|cvv|card number|information).{0,50}(verify|confirm|secure)/i, label: 'Credential harvesting', score: 65, type: 'phishing' },
    { pattern: /log(in| in).{0,30}(immediately|now|urgently|within \d+|as soon as)/i, label: 'Urgent login demand', score: 50, type: 'phishing' },
    { pattern: /verify.{1,20}(identity|account|details|information).{1,100}(now|immediately|within|to avoid)/i, label: 'Strict verification demand', score: 60, type: 'phishing' },
    { pattern: /action required.{0,50}(account|bank|card)/i, label: 'Required action hook', score: 45, type: 'phishing' },

    // ── PHISHING (BM) ──
    { pattern: /akaun (anda|kamu).{0,20}(telah |sudah |akan )?(digantung|dibekukan|disekat|terhad|dikompromikan)/i, label: 'Account suspension threat (BM)', score: 55, type: 'phishing' },
    { pattern: /sila.{1,20}(klik|tekan|lawati).{1,20}(pautan|link|url|di sini)/i, label: 'Phishing link prompt (BM)', score: 50, type: 'phishing' },
    { pattern: /(masukkan|berikan|hantar).{1,20}(otp|pin|kata laluan|nombor kad)/i, label: 'Credential harvesting (BM)', score: 65, type: 'phishing' },
    { pattern: /dalam.{0,20}(tempoh )?\d+.{1,20}(jam|minit|hari).{0,30}akaun/i, label: 'Time-pressure account threat (BM)', score: 50, type: 'phishing' },
    { pattern: /pengesahan.{1,20}(akaun|identiti|maklumat).{1,20}(anda|diperlukan)/i, label: 'Verification demand (BM)', score: 45, type: 'phishing' },

    // ── PHISHING (ZH) ──
    { pattern: /您的(账号|账户|银行卡|信用卡)(已被|将被)?(冻结|暂停|限制|封锁)/i, label: 'Account freeze threat (ZH)', score: 55, type: 'phishing' },
    { pattern: /(点击|点此|立即点击)(链接|验证|登录|确认)/i, label: 'Phishing link (ZH)', score: 50, type: 'phishing' },
    { pattern: /(输入|提供|发送)(您的|你的)?(密码|验证码|OTP|PIN码|银行卡号)/i, label: 'Credential harvesting (ZH)', score: 65, type: 'phishing' },

    // ── IMPERSONATION — Malaysian Authorities ──
    { pattern: /(lhdn|hasil|irb|lembaga hasil dalam negeri)/i, label: 'LHDN/Tax authority impersonation', score: 40, type: 'impersonation' },
    { pattern: /(kwsp|epf|kumpulan wang simpanan pekerja)/i, label: 'KWSP/EPF impersonation', score: 40, type: 'impersonation' },
    { pattern: /(pdrm|polis diraja malaysia|balai polis|ibu pejabat polis)/i, label: 'PDRM impersonation', score: 45, type: 'impersonation' },
    { pattern: /(bank negara|bnm|central bank of malaysia)/i, label: 'Bank Negara impersonation', score: 45, type: 'impersonation' },
    { pattern: /(sprm|badan pencegah rasuah|macc)/i, label: 'SPRM/MACC impersonation', score: 45, type: 'impersonation' },
    { pattern: /(jabatan imigresen|immigration department)/i, label: 'Immigration Dept impersonation', score: 40, type: 'impersonation' },
    { pattern: /(mahkamah|court order|saman|waran tangkap)/i, label: 'Court/legal threat', score: 50, type: 'impersonation' },
    { pattern: /(celcom|maxis|digi|umobile|telekom malaysia|unifi)\s+(account|akaun)/i, label: 'Telco impersonation', score: 35, type: 'impersonation' },

    // ── INVESTMENT SCAM ──
    { pattern: /(\d+%|percent) (guaranteed|dijamin) (return|profit|keuntungan|pulangan)/i, label: 'Guaranteed returns claim', score: 55, type: 'investment' },
    { pattern: /(pelaburan|investment).{0,30}(untung|profit|return).{0,20}(tinggi|high|besar|guaranteed)/i, label: 'High-return investment', score: 50, type: 'investment' },
    { pattern: /modal (rendah|minimum|kecil|rm\d+).{0,30}(keuntungan|untung|pulangan)/i, label: 'Low capital high return investment', score: 50, type: 'investment' },
    { pattern: /(forex|crypto|bitcoin|cryptocurrency).{0,30}(guaranteed|dijamin|100%|pasti untung)/i, label: 'Crypto/Forex guaranteed return', score: 60, type: 'investment' },
    { pattern: /join (our |my )?(group|whatsapp|telegram).{0,30}(invest|profit|earn|income)/i, label: 'Investment group recruitment', score: 45, type: 'investment' },
    { pattern: /(passive income|pendapatan pasif).{0,30}(dari rumah|from home|sehari|per day)/i, label: 'Passive income from home', score: 45, type: 'investment' },

    // ── LOTTERY / PRIZE SCAM ──
    { pattern: /(you have won|anda telah menang|tahniah).{0,50}(rm|myr|\$|prize|hadiah|cash)/i, label: 'Lottery/prize winner claim', score: 60, type: 'lottery' },
    { pattern: /(lucky (draw|winner)|pertandingan|cabutan bertuah)/i, label: 'Lucky draw scam', score: 40, type: 'lottery' },
    { pattern: /(collect|tuntut|claim).{0,30}(prize|hadiah|reward|wang|cash).{0,20}(now|sekarang|segera)/i, label: 'Prize collection pressure', score: 55, type: 'lottery' },
    { pattern: /rm\s*\d{4,}(,\d{3})*.{0,30}(won|menang|hadiah|prize|reward)/i, label: 'Large prize claim (RM)', score: 55, type: 'lottery' },

    // ── ROMANCE SCAM ──
    { pattern: /(send|transfer|hantar).{0,30}(money|wang|rm|fund).{0,30}(emergency|kecemasan|hospital|accident)/i, label: 'Romance emergency money request', score: 60, type: 'romance' },
    { pattern: /(fell in love|jatuh cinta).{0,50}(send|hantar|transfer)/i, label: 'Romance money solicitation', score: 55, type: 'romance' },

    // ── DELIVERY SCAM ──
    { pattern: /(parcel|package|bungkusan|courier).{0,40}(ditahan|seized|held|custom|kastam)/i, label: 'Parcel/customs seized scam', score: 55, type: 'delivery' },
    { pattern: /(pos malaysia|poslaju|dhl|fedex|j&t|ninjavan).{0,40}(bayar|payment|fee|denda|fine)/i, label: 'Delivery fee scam', score: 55, type: 'delivery' },

    // ── TECH SUPPORT SCAM ──
    { pattern: /(your (computer|device|phone)|peranti anda).{0,30}(virus|hacked|infected|compromised)/i, label: 'Tech support virus scare', score: 55, type: 'tech_support' },
    { pattern: /(microsoft|apple|google).{0,20}(technical (support|team)|virus alert|security alert)/i, label: 'Big tech impersonation', score: 60, type: 'tech_support' },
];

/** Urgency amplifiers — boost score when present with other signals */
const URGENCY_PATTERNS: Array<{ pattern: RegExp; label: string }> = [
    { pattern: /\b(urgent|segera|immediate(ly)?|sekarang juga|right now|dalam masa)\b/i, label: 'Urgency language' },
    { pattern: /\b(24 (jam|hours?)|48 (jam|hours?)|within \d+ (hour|jam|day|hari))\b/i, label: 'Time-limit threat' },
    { pattern: /\b(atau (akaun|account) (anda|you).{0,20}(dibekukan|suspended|blocked|ditutup|closed))\b/i, label: 'Account closure threat' },
    { pattern: /!{2,}/, label: 'Excessive exclamation marks' },
    { pattern: /[A-Z]{5,}/, label: 'All-caps urgency' },
];

/** Suspicious financial keywords */
const FINANCIAL_PATTERNS: Array<{ pattern: RegExp; label: string }> = [
    { pattern: /\bRM\s*\d{3,}/i, label: 'Large RM amount mentioned' },
    { pattern: /\btransfer (wang|money|fund|rm)/i, label: 'Money transfer request' },
    { pattern: /\b(bank account|nombor akaun|account number)\b/i, label: 'Bank account solicitation' },
    { pattern: /\b(western union|wire transfer|bitcoin|crypto wallet|e-wallet)\b/i, label: 'Suspicious payment method' },
];

// ── Language Detection ──────────────────────────────────────────────────────

function detectLanguage(text: string): Language {
    const zhChars = (text.match(/[\u4e00-\u9fff]/g) || []).length;
    const bmWords = (text.match(/\b(sila|anda|akaun|wang|klik|segera|pautan|maklumat|telah|nombor|dalam|untuk)\b/gi) || []).length;
    const enWords = (text.match(/\b(your|account|please|click|bank|verify|click|link|suspended|transfer)\b/gi) || []).length;

    const total = text.split(/\s+/).length;
    const zhRatio = zhChars / text.length;
    const bmRatio = bmWords / total;
    const enRatio = enWords / total;

    if (zhRatio > 0.2) return zhChars > 20 && bmWords < 2 && enWords < 2 ? 'zh' : 'mixed';
    if (bmRatio > enRatio && bmRatio > 0.05) return enRatio > 0.05 ? 'mixed' : 'ms';
    if (enRatio > 0.05) return 'en';
    return 'mixed';
}

// ── Main Service ────────────────────────────────────────────────────────────

export class NlpMessageService {
    static analyze(message: string): MessageAnalysisResult {
        const text = message.trim();
        let score = 0;
        const matchedPatterns: string[] = [];
        const highlightedPhrases: string[] = [];
        let dominantScamType: ScamType = null;
        const scamTypeCounts: Record<string, number> = {};

        // 1. Scam phrase matching
        for (const { pattern, label, score: weight, type } of SCAM_PHRASES) {
            const match = text.match(pattern);
            if (match) {
                score += weight;
                matchedPatterns.push(label);
                if (match[0]) highlightedPhrases.push(match[0].trim());
                if (type) scamTypeCounts[type] = (scamTypeCounts[type] ?? 0) + weight;
            }
        }

        // 2. Urgency amplifiers (only boost if base score > 0)
        let urgencyBoost = 0;
        for (const { pattern, label } of URGENCY_PATTERNS) {
            if (pattern.test(text)) {
                urgencyBoost += 15;
                matchedPatterns.push(label);
            }
        }
        if (score > 0) score += Math.min(urgencyBoost, 30); // Cap urgency boost

        // 3. Financial triggers (only boost if base score > 0)
        let financialBoost = 0;
        for (const { pattern, label } of FINANCIAL_PATTERNS) {
            if (pattern.test(text)) {
                financialBoost += 15;
                matchedPatterns.push(label);
            }
        }
        if (score > 0) score += Math.min(financialBoost, 25);

        // 4. Determine dominant scam type
        if (Object.keys(scamTypeCounts).length > 0) {
            dominantScamType = Object.entries(scamTypeCounts).sort((a, b) => b[1] - a[1])[0][0] as ScamType;
        }

        // 5. Deduplicate
        const uniquePatterns = [...new Set(matchedPatterns)];
        const uniquePhrases = [...new Set(highlightedPhrases)];

        // 6. Cap score and determine level
        const finalScore = Math.min(score, 100);
        const level = NlpMessageService._getLevel(finalScore);

        // 7. Language detection
        const language = detectLanguage(text);

        if (finalScore === 0) {
            uniquePatterns.push('✅ No scam patterns detected');
        }

        return {
            score: finalScore,
            level,
            scamType: dominantScamType,
            language,
            matchedPatterns: uniquePatterns,
            highlightedPhrases: uniquePhrases,
            checkedAt: new Date().toISOString(),
        };
    }

    private static _getLevel(score: number): 'low' | 'medium' | 'high' | 'critical' {
        if (score >= 80) return 'critical';
        if (score >= 55) return 'high';
        if (score >= 30) return 'medium';
        return 'low';
    }
}
