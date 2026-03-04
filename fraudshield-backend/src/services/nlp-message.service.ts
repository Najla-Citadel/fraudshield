export type ScamType =
    | 'phishing'
    | 'investment'
    | 'impersonation'
    | 'lottery'
    | 'romance'
    | 'delivery'
    | 'tech_support'
    | 'macau_scam'
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
    { pattern: /(pdrm|polis diraja malaysia|balai polis|ibu pejabat polis|马(来西亚)?警(方|察)|警察局)/i, label: 'PDRM impersonation', score: 45, type: 'impersonation' },
    { pattern: /(bank negara|bnm|central bank of malaysia|国(家)?银行|央行)/i, label: 'Bank Negara impersonation', score: 45, type: 'impersonation' },
    { pattern: /(sprm|badan pencegah rasuah|macc|反贪会)/i, label: 'SPRM/MACC impersonation', score: 45, type: 'impersonation' },
    { pattern: /(jabatan imigresen|immigration department|移民局)/i, label: 'Immigration Dept impersonation', score: 40, type: 'impersonation' },
    { pattern: /(mahkamah|court order|saman|waran tangkap|法院|法庭|传票|逮捕令)/i, label: 'Court/legal threat', score: 50, type: 'impersonation' },
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

    // ── MACAU SCAM (Composite Indicators) ──
    { pattern: /(safe account|akaun selamat|akaun bank negara|安全账户|安全帐户)/i, label: 'Macau Scam "safe account" narrative', score: 60, type: 'macau_scam' },
    { pattern: /(siasatan|investigation|crime case|kes jenayah|犯罪案件|调查).{0,50}(transfer|pindahkan|deposit|bayar|转账|支付|存入)/i, label: 'Macau Scam investigation pressure', score: 55, type: 'macau_scam' },
    { pattern: /(waran tangkap|saman mahkamah|arrest warrant|court order|逮捕令|法院传票|法庭传票)/i, label: 'Legal/arrest threat', score: 50, type: 'macau_scam' },
    { pattern: /(cukai tertunggak|tax evasion|outstanding tax|lhdn.{0,20}bayar|欠税|偷税漏税)/i, label: 'Tax threat narrative', score: 50, type: 'macau_scam' },
    { pattern: /(ibu pejabat polis|bukit aman|bnm taskforce|pegawai penyiasat|investigation officer)/i, label: 'Authoritarian identity pressure', score: 45, type: 'macau_scam' },
    { pattern: /(pindahkan.{0,20}akaun bnm|transfer.{0,20}safe account|audit fund|money audit)/i, label: 'Audit narrative', score: 60, type: 'macau_scam' },
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
const FINANCIAL_PATTERNS: Array<{ pattern: RegExp; label: string; score: number }> = [
    { pattern: /\b(transfer|pindahkan|hantar|bayar|pay|deposit|send|转账|支付|存入).{0,20}(wang|money|fund|rm|credit|amount|金|钱|款)/i, label: 'Financial transaction mention', score: 15 },
    { pattern: /\b(bank account|akaun bank|bank card|credit card|debit card|银行卡|银行账户|信用卡)/i, label: 'Banking instrument mention', score: 10 },
    { pattern: /\b(safe account|akaun selamat|akaun bank negara|安全账户|安全帐户)/i, label: 'Safe account narrative', score: 20 },
    { pattern: /\b(western union|wire transfer|bitcoin|crypto wallet|e-wallet)\b/i, label: 'Suspicious payment method', score: 15 },
    { pattern: /\bRM\s*\d{3,}/i, label: 'Large RM amount mentioned', score: 10 },
    { pattern: /\b(pindahkan maklumat|audit keselamatan|pegawai audit)\b/i, label: 'Review/Audit pressure', score: 15 },
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

        // 4. Determine dominant scam type & apply Macau Scam composite boost
        let isAuthority = false;
        let isMoneyDemand = false;

        for (const pattern of SCAM_PHRASES) {
            const isMatch = pattern.pattern.test(text);
            if (isMatch) {
                if (pattern.type === 'impersonation') isAuthority = true;
                if (pattern.type === 'macau_scam') {
                    // Macau Scam patterns usually contain BOTH authority and money demand signals
                    isAuthority = true;
                    isMoneyDemand = true;
                }
            }
        }
        if (FINANCIAL_PATTERNS.some(p => p.pattern.test(text))) isMoneyDemand = true;

        if (isAuthority && isMoneyDemand) {
            score += 25; // Composite boost
            if (!matchedPatterns.includes('Macau Scam Indicators: Authority Impersonation + Money Demand')) {
                matchedPatterns.push('Macau Scam Indicators: Authority Impersonation + Money Demand');
            }
            dominantScamType = 'macau_scam';
        } else if (Object.keys(scamTypeCounts).length > 0) {
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
