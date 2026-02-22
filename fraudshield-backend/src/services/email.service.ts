// fraudshield-backend/src/services/email.service.ts
import { createClient } from 'redis';
import crypto from 'crypto';

export class EmailService {
    private static redisClient: ReturnType<typeof createClient>;
    private static isConnected = false;

    static async init() {
        if (!this.redisClient) {
            this.redisClient = createClient({
                url: process.env.REDIS_URL || 'redis://localhost:6379'
            });

            this.redisClient.on('error', (err) => console.error('Redis Client Error', err));
            await this.redisClient.connect();
            this.isConnected = true;
        }
    }

    /**
     * Generates a 6-digit OTP and stores it in Redis for 15 minutes.
     */
    static async generatePasswordResetOtp(email: string): Promise<string> {
        if (!this.isConnected) await this.init();

        // 1. Generate 6 digit OTP
        const otp = crypto.randomInt(100000, 999999).toString();

        // 2. Store in Redis with 15-minute expiration (900 seconds)
        const redisKey = `reset_otp:${email}`;
        await this.redisClient.setEx(redisKey, 900, otp);

        // 3. Mock sending email
        console.log(`\n=========================================`);
        console.log(`📧 MOCK EMAIL SENT TO: ${email}`);
        console.log(`🔒 PASSWORD RESET OTP: ${otp}`);
        console.log(`=========================================\n`);

        return otp; // Return it so in dev environments we can auto-fill it or display it
    }

    /**
     * Verifies the OTP provided by the user against Redis.
     */
    static async verifyPasswordResetOtp(email: string, otp: string): Promise<boolean> {
        if (!this.isConnected) await this.init();

        const redisKey = `reset_otp:${email}`;
        const storedOtp = await this.redisClient.get(redisKey);

        if (!storedOtp || storedOtp !== otp) {
            return false;
        }

        // OTP is valid! Delete it so it cannot be reused.
        await this.redisClient.del(redisKey);

        return true;
    }
}
