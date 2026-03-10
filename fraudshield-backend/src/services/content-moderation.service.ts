import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class ContentModerationService {
    /**
     * Scans report description for PII (Personal Identifiable Information)
     * and potentially offensive content using regex (mocking AI for now).
     */
    static async screenReport(description: string): Promise<{
        isFlagged: boolean;
        reasons: string[];
    }> {
        const reasons: string[] = [];

        // 1. PII Detection (Malaysian Context)
        const malaysiaICRegex = /\b\d{6}-?\d{2}-?\d{4}\b/g;
        if (malaysiaICRegex.test(description)) {
            reasons.push('Contains potential Malaysian IC Number');
        }

        const emailRegex = /\b[A-Za-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b/gi;
        if (emailRegex.test(description)) {
            reasons.push('Contains potential Email Address');
        }

        const phoneRegex = /\b(01[0-9]-?\d{7,8}|0[3-9]-?\d{7,8})\b/g;
        if (phoneRegex.test(description)) {
            reasons.push('Contains potential Phone Number');
        }

        // 2. Mock AI Content Safety
        // In a real scenario, this would call OpenAI Moderation API
        const sensitiveWords = ['babi', 'pundek', 'bodoh', 'stfu', 'kill'];
        const lowerDesc = description.toLowerCase();
        if (sensitiveWords.some(word => lowerDesc.includes(word))) {
            reasons.push('Contains offensive language');
        }

        return {
            isFlagged: reasons.length > 0,
            reasons,
        };
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
