// fraudshield-backend/src/services/email.service.ts
import { createClient } from 'redis';
import crypto from 'crypto';
import nodemailer from 'nodemailer';

export class EmailService {
    private static redisClient: ReturnType<typeof createClient>;
    private static isConnected = false;
    private static transporter: nodemailer.Transporter | null = null;

    static async init() {
        if (!this.redisClient) {
            const redisUrl = process.env.REDIS_URL;
            const redisHost = process.env.REDIS_HOST || 'localhost';
            const redisPort = process.env.REDIS_PORT || '6379';
            const redisPassword = process.env.REDIS_PASSWORD;

            const url = redisUrl || (redisPassword
                ? `redis://:${redisPassword}@${redisHost}:${redisPort}`
                : `redis://${redisHost}:${redisPort}`);

            this.redisClient = createClient({ url });

            this.redisClient.on('error', (err) => console.error('Redis Client Error', err));
            await this.redisClient.connect();
            this.isConnected = true;
        }

        if (!this.transporter) {
            this.transporter = nodemailer.createTransport({
                host: process.env.SMTP_HOST || 'smtp.mailtrap.io',
                port: parseInt(process.env.SMTP_PORT || '2525'),
                secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
                auth: {
                    user: process.env.SMTP_USER,
                    pass: process.env.SMTP_PASS,
                },
            });
        }
    }

    /**
     * Generates a 6-digit OTP and stores it in Redis for 15 minutes.
     * Also sends a real email if SMTP is configured.
     */
    static async generatePasswordResetOtp(email: string): Promise<string> {
        if (!this.isConnected || !this.transporter) await this.init();

        // 1. Generate 6 digit OTP
        const otp = crypto.randomInt(100000, 999999).toString();

        // 2. Store in Redis with 15-minute expiration (900 seconds)
        const redisKey = `reset_otp:${email}`;
        await this.redisClient.setEx(redisKey, 900, otp);

        // 3. Send real email
        const mailOptions = {
            from: process.env.SMTP_FROM || '"FraudShield" <noreply@fraudshieldprotect.com>',
            to: email,
            subject: 'Password Reset Code - FraudShield',
            html: `
                <div style="font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
                    <div style="text-align: center; margin-bottom: 30px;">
                        <h1 style="color: #0f172a; margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.025em;">FraudShield</h1>
                        <p style="color: #64748b; margin-top: 4px; font-size: 14px;">Protecting your digital assets</p>
                    </div>
                    
                    <div style="margin-bottom: 30px;">
                        <h2 style="color: #0f172a; font-size: 18px; font-weight: 600; margin-bottom: 16px;">Reset your password</h2>
                        <p style="color: #475569; font-size: 16px; line-height: 24px; margin-bottom: 24px;">
                            We received a request to reset your password. Use the verification code below to proceed with the reset. This code will expire in 15 minutes.
                        </p>
                        
                        <div style="background-color: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 8px; padding: 24px; text-align: center; margin-bottom: 24px;">
                            <span style="font-family: 'JetBrains Mono', monospace; font-size: 36px; font-weight: 700; color: #0f172a; letter-spacing: 0.2em;">${otp}</span>
                        </div>
                        
                        <p style="color: #64748b; font-size: 14px; line-height: 20px;">
                            If you didn't request a password reset, you can safely ignore this email. Someone might have typed your email address by mistake.
                        </p>
                    </div>
                    
                    <div style="border-top: 1px solid #e2e8f0; padding-top: 24px; text-align: center;">
                        <p style="color: #94a3b8; font-size: 12px; margin: 0;">
                            &copy; ${new Date().getFullYear()} FraudShield. All rights reserved.
                        </p>
                    </div>
                </div>
            `,
        };

        try {
            await this.transporter!.sendMail(mailOptions);
            console.log(`📧 Email sent successfully to: ${email}`);
        } catch (error) {
            console.error('Failed to send email:', error);
            // In local development, we still want to see the OTP even if email fails
            if (process.env.NODE_ENV === 'development') {
                console.log(`\n=========================================`);
                console.log(`🔒 PASSWORD RESET OTP (FALLBACK): ${otp}`);
                console.log(`=========================================\n`);
            }
        }

        return otp;
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

    /**
     * Generates a 6-digit OTP for email verification and stores it in Redis for 15 minutes.
     * Also sends a real email if SMTP is configured.
     */
    static async generateEmailVerificationOtp(email: string): Promise<string> {
        if (!this.isConnected || !this.transporter) await this.init();

        // 1. Generate 6 digit OTP
        const otp = crypto.randomInt(100000, 999999).toString();

        // 2. Store in Redis with 15-minute expiration (900 seconds)
        const redisKey = `verify_otp:${email}`;
        await this.redisClient.setEx(redisKey, 900, otp);

        // 3. Send real email
        const mailOptions = {
            from: process.env.SMTP_FROM || '"FraudShield" <noreply@fraudshieldprotect.com>',
            to: email,
            subject: 'Verify your email address - FraudShield',
            html: `
                <div style="font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
                    <div style="text-align: center; margin-bottom: 30px;">
                        <h1 style="color: #0f172a; margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.025em;">FraudShield</h1>
                        <p style="color: #64748b; margin-top: 4px; font-size: 14px;">Protecting your digital assets</p>
                    </div>
                    
                    <div style="margin-bottom: 30px;">
                        <h2 style="color: #0f172a; font-size: 18px; font-weight: 600; margin-bottom: 16px;">Welcome to FraudShield!</h2>
                        <p style="color: #475569; font-size: 16px; line-height: 24px; margin-bottom: 24px;">
                            Please verify your email address to complete your registration. Use the verification code below:
                        </p>
                        
                        <div style="background-color: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 8px; padding: 24px; text-align: center; margin-bottom: 24px;">
                            <span style="font-family: 'JetBrains Mono', monospace; font-size: 36px; font-weight: 700; color: #0f172a; letter-spacing: 0.2em;">${otp}</span>
                        </div>
                        
                        <p style="color: #64748b; font-size: 14px; line-height: 20px;">
                            This code will expire in 15 minutes. If you did not sign up for FraudShield, please ignore this email.
                        </p>
                    </div>
                    
                    <div style="border-top: 1px solid #e2e8f0; padding-top: 24px; text-align: center;">
                        <p style="color: #94a3b8; font-size: 12px; margin: 0;">
                            &copy; ${new Date().getFullYear()} FraudShield. All rights reserved.
                        </p>
                    </div>
                </div>
            `,
        };

        try {
            await this.transporter!.sendMail(mailOptions);
            console.log(`📧 Verification email sent successfully to: ${email}`);
        } catch (error) {
            console.error('Failed to send verification email:', error);
            // In local development, we still want to see the OTP even if email fails
            if (process.env.NODE_ENV === 'development') {
                console.log(`\n=========================================`);
                console.log(`✉️ EMAIL VERIFICATION OTP (FALLBACK): ${otp}`);
                console.log(`=========================================\n`);
            }
        }

        return otp;
    }

    /**
     * Verifies the email verification OTP provided by the user against Redis.
     */
    static async verifyEmailOtp(email: string, otp: string): Promise<boolean> {
        if (!this.isConnected) await this.init();

        const redisKey = `verify_otp:${email}`;
        const storedOtp = await this.redisClient.get(redisKey);

        if (!storedOtp || storedOtp !== otp) {
            return false;
        }

        // OTP is valid! Delete it so it cannot be reused.
        await this.redisClient.del(redisKey);

        return true;
    }
}
