import { NlpMessageService } from '../src/services/nlp-message.service';

describe('NlpMessageService', () => {
    describe('Phishing detection — English', () => {
        it('detects account suspension + click link phishing (EN)', () => {
            const msg = 'Your account has been suspended. Click here to verify your identity now.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(55);
            expect(['high', 'critical']).toContain(result.level);
            expect(result.scamType).toBe('phishing');
        });

        it('detects OTP solicitation', () => {
            const msg = 'Your OTP is about to expire. Please enter your OTP immediately to keep access.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(50);
            expect(result.scamType).toBe('phishing');
        });

        it('detects credential harvesting', () => {
            const msg = 'Please enter your password and PIN to confirm your banking details.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(55);
            expect(result.scamType).toBe('phishing');
        });
    });

    describe('Phishing detection — Bahasa Malaysia', () => {
        it('detects BM account suspension + time pressure', () => {
            const msg = 'Akaun anda telah digantung. Sila klik pautan ini dalam 24 jam atau akaun anda akan dibekukan.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(50);
            expect(['medium', 'high', 'critical']).toContain(result.level);
            expect(result.scamType).toBe('phishing');
            expect(['ms', 'mixed']).toContain(result.language);
        });

        it('detects BM credential harvesting', () => {
            const msg = 'Masukkan PIN dan kata laluan anda untuk pengesahan akaun.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(55);
        });
    });

    describe('Phishing detection — Chinese', () => {
        it('detects ZH account freeze threat', () => {
            const msg = '您的账号已被冻结，请立即点击链接验证您的身份。';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(50);
            expect(result.language).toBe('zh');
        });
    });

    describe('Impersonation detection — Malaysian authorities', () => {
        it('detects LHDN impersonation', () => {
            const msg = 'LHDN: Cukai anda perlu dibayar dalam 24 jam atau akaun akan dibekukan.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(50);
            // Result could be phishing or impersonation depending on weights
            expect(['phishing', 'impersonation']).toContain(result.scamType);
        });

        it('detects PDRM (police) impersonation', () => {
            const msg = 'Polis Diraja Malaysia: Anda dikehendaki hadir ke balai polis dalam 24 jam.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(50);
            expect(result.scamType).toBe('impersonation');
        });

        it('detects Bank Negara impersonation', () => {
            const msg = 'This is Bank Negara Malaysia. Your account has been compromised. Verify now.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(55);
            expect(['phishing', 'impersonation']).toContain(result.scamType);
        });

        it('detects KWSP/EPF impersonation', () => {
            const msg = 'KWSP: Simpanan EPF anda akan ditamatkan. Sila kemaskini akaun anda segera.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(35);
            expect(result.scamType).toBe('impersonation');
        });
    });

    describe('Investment scam detection', () => {
        it('detects guaranteed return investment scam', () => {
            const msg = 'Join our crypto investment group! 50% guaranteed return within 30 days. Limited slots!';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(50);
            expect(result.scamType).toBe('investment');
        });

        it('detects BM investment scam', () => {
            const msg = 'Pelaburan modal rendah untung tinggi dijamin! Sertai group Telegram kami sekarang.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(50);
            expect(result.scamType).toBe('investment');
        });
    });

    describe('Lottery scam detection', () => {
        it('detects EN lottery winner claim', () => {
            const msg = 'Congratulations! You have won RM5000 in our lucky draw. Claim your prize now!';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(55);
            expect(result.scamType).toBe('lottery');
        });

        it('detects BM prize scam', () => {
            const msg = 'Tahniah! Anda telah menang cabutan bertuah RM3000. Tuntut hadiah anda sekarang.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(50);
            expect(result.scamType).toBe('lottery');
        });
    });

    describe('Delivery scam detection', () => {
        it('detects parcel/customs scam', () => {
            const msg = 'Your parcel has been seized at customs. Bayar RM50 untuk melepaskan bungkusan anda.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeGreaterThanOrEqual(35);
            expect(result.scamType).toBe('delivery');
        });
    });

    describe('Clean message detection', () => {
        it('returns low score for a normal friendly message', () => {
            const msg = 'Hi, can we meet for lunch tomorrow at the usual place? I will bring the files.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeLessThanOrEqual(15);
            expect(result.level).toBe('low');
            expect(result.scamType).toBeNull();
        });

        it('returns low score for a business reminder', () => {
            const msg = 'Reminder: Your invoice INV-2024-001 is due on March 1st. Please process payment.';
            const result = NlpMessageService.analyze(msg);
            expect(result.score).toBeLessThanOrEqual(25);
        });
    });

    describe('Language detection', () => {
        it('detects English dominant messages', () => {
            const msg = 'Your bank account has been suspended. Click here to verify your account now.';
            const result = NlpMessageService.analyze(msg);
            expect(result.language).toBe('en');
        });

        it('detects Bahasa Malaysia dominant messages', () => {
            const msg = 'Akaun bank anda telah digantung. Sila klik pautan untuk pengesahan.';
            const result = NlpMessageService.analyze(msg);
            expect(['ms', 'mixed']).toContain(result.language);
        });

        it('detects Chinese dominant messages', () => {
            const msg = '您的银行账户已暂停，请立即点击验证链接以恢复访问。';
            const result = NlpMessageService.analyze(msg);
            expect(result.language).toBe('zh');
        });
    });

    describe('Highlighted phrases', () => {
        it('includes matched phrases in highlightedPhrases', () => {
            const msg = 'Your account has been suspended. Click here to verify your identity.';
            const result = NlpMessageService.analyze(msg);
            expect(result.highlightedPhrases.length).toBeGreaterThan(0);
        });
    });
});
