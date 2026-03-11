import { PrismaClient } from '@prisma/client';
import axios from 'axios';

const prisma = new PrismaClient();
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

export class ContentModerationService {
    /**
     * Scans content (reports or comments) for PII (Personal Identifiable Information)
     * and potentially offensive content using AI and regex.
     */
    static async screenContent(content: string): Promise<{
        isFlagged: boolean;
        reasons: string[];
    }> {
        const reasons: string[] = [];

        // 1. PII Detection (Malaysian Context)
        const malaysiaICRegex = /\b\d{6}-?\d{2}-?\d{4}\b/g;
        if (malaysiaICRegex.test(content)) {
            reasons.push('Contains potential Malaysian IC Number');
        }

        const emailRegex = /\b[A-Za-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b/gi;
        if (emailRegex.test(content)) {
            reasons.push('Contains potential Email Address');
        }

        const phoneRegex = /\b(01[0-9]-?\d{7,8}|0[3-9]-?\d{7,8})\b/g;
        if (phoneRegex.test(content)) {
            reasons.push('Contains potential Phone Number');
        }

        // 1b. Address/Location PII Detection (Malaysian Context)
        const addressRegex = /\b(jalan|lorong|taman|kampung|persiaran|lebuhraya|no\.\s?\d+|blk\s?\d+|tingkat\s?\d+|lot\s?\d+)\b/gi;
        if (addressRegex.test(content)) {
            reasons.push('Contains potential Physical Address');
        }

        const postcodeRegex = /\b\d{5}\s+(kuala lumpur|selangor|johor|penang|perak|sabah|sarawak|melaka|pahang|kelantan|terengganu|perlis|kedah|negeri sembilan|putrajaya|labuan)\b/gi;
        if (postcodeRegex.test(content)) {
            reasons.push('Contains potential Postcode + State');
        }

        // 1c. Off-Topic / Spam Detection
        const offTopicResult = this.detectOffTopic(content);
        if (offTopicResult) {
            reasons.push(offTopicResult);
        }

        // 2. AI Content Safety (OpenAI Moderation)
        if (OPENAI_API_KEY) {
            try {
                const response = await axios.post(
                    'https://api.openai.com/v1/moderations',
                    { input: content },
                    {
                        headers: {
                            'Authorization': `Bearer ${OPENAI_API_KEY}`,
                            'Content-Type': 'application/json',
                        },
                    }
                );

                const result = (response.data as any).results[0];
                if (result.flagged) {
                    // Extract categories that were flagged
                    const categories = result.categories;
                    const flaggedCategories = Object.keys(categories).filter(
                        (cat) => categories[cat] === true
                    );
                    reasons.push(`AI Flagged: ${flaggedCategories.join(', ')}`);
                }
            } catch (error: any) {
                console.error('❌ OpenAI Moderation API Error:', error?.response?.data || error.message);
                // Fallback to basic keyword check if API fails
                const sensitiveWords = ['babi', 'pundek', 'bodoh', 'stfu', 'kill'];
                const lowerDesc = content.toLowerCase();
                if (sensitiveWords.some(word => lowerDesc.includes(word))) {
                    reasons.push('Contains offensive language (Fallback)');
                }
            }
        } else {
            // TODO: Ensure OPENAI_API_KEY is configured for production
            console.warn('⚠️ OpenAI API Key missing. Falling back to simple keyword filter.');
            const sensitiveWords = ['babi', 'pundek', 'bodoh', 'stfu', 'kill'];
            const lowerDesc = content.toLowerCase();
            if (sensitiveWords.some(word => lowerDesc.includes(word))) {
                reasons.push('Contains offensive language (Mock)');
            }
        }

        return {
            isFlagged: reasons.length > 0,
            reasons,
        };
    }

    /**
     * Detects off-topic, political, or spam/promotional content.
     * Returns a reason string if flagged, or null if clean.
     */
    private static detectOffTopic(text: string): string | null {
        const lower = text.toLowerCase();

        // Political keywords (Malaysian context)
        const politicalPatterns = [
            /\b(undi|mengundi|pilihan\s?raya|pru\d+|election|vote\s+for)\b/i,
            /\b(parti|umno|pas|pkr|dap|bersatu|warisan|pejuang|muda|gerakan|mca|mic)\b/i,
            /\b(perdana\s+menteri|menteri\s+besar|chief\s+minister|anwar|mahathir|najib|muhyiddin)\b/i,
        ];
        if (politicalPatterns.some(p => p.test(lower))) {
            return 'Off-topic: Contains political content';
        }

        // Spam / promotional keywords
        const spamPatterns = [
            /\b(buy\s+now|order\s+now|limited\s+offer|act\s+fast|hurry)\b/i,
            /\b(free\s+gift|giveaway|claim\s+your|congratulations?\s+you\s+won)\b/i,
            /\b(discount|promo\s?code|coupon|sale\s+ending|clearance)\b/i,
            /\b(click\s+here|join\s+now|sign\s+up\s+free|subscribe\s+now)\b/i,
            /\b(earn\s+money|work\s+from\s+home|passive\s+income|side\s+hustle)\b/i,
            /\b(whatsapp\s+me|dm\s+me|telegram\s+me|contact\s+me\s+at)\b/i,
        ];
        if (spamPatterns.some(p => p.test(lower))) {
            return 'Off-topic: Contains promotional/spam content';
        }

        // Religious / divisive content
        const divisivePatterns = [
            /\b(kafir|murtad|haram\s+jadah|anti[- ]islam|anti[- ]malay|anti[- ]chinese|anti[- ]indian)\b/i,
        ];
        if (divisivePatterns.some(p => p.test(lower))) {
            return 'Off-topic: Contains divisive/inflammatory content';
        }

        return null;
    }

    /**
     * Extracts potential scam entities from a text description.
     */
    static async extractEntities(text: string): Promise<{
        phones: string[];
        emails: string[];
        bankAccounts: string[];
        urls: string[];
    }> {
        const phones = text.match(/\b(01[0-9]-?\d{7,8}|0[3-9]-?\d{7,8})\b/g) || [];
        const emails = text.match(/\b[A-Za-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b/gi) || [];
        const bankAccounts = text.match(/\b\d{10,16}\b/g) || [];
        const urls = text.match(/https?:\/\/(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&//=]*)/g) || [];

        return {
            phones: [...new Set(phones)],
            emails: [...new Set(emails)],
            bankAccounts: [...new Set(bankAccounts)],
            urls: [...new Set(urls)],
        };
    }
}
