export class ContentFilter {
    // URL pattern detection
    private static readonly URL_REGEX = /https?:\/\/[^\s]+|www\.[^\s]+/gi;

    // Basic profanity list (Malay & English)
    private static readonly BLOCKED_PATTERNS = [
        /\b(bodoh|sial|babi|celaka|pukimak|anjing|pantat|lanjau)\b/gi,
        /\b(fuck|shit|asshole|bitch|bastard|dick|pussy)\b/gi,
    ];

    static sanitize(text: string): { clean: string; blocked: boolean; reason?: string } {
        // 1. Check for URLs
        if (this.URL_REGEX.test(text)) {
            return { clean: text, blocked: true, reason: 'Comments cannot contain URLs' };
        }

        // 2. Check profanity
        for (const pattern of this.BLOCKED_PATTERNS) {
            if (pattern.test(text)) {
                return { clean: text, blocked: true, reason: 'Comment contains inappropriate language' };
            }
        }

        return { clean: text.trim(), blocked: false };
    }
}
