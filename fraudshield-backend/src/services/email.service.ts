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

    /**
     * Sends a consolidated daily scam digest to the user.
     */
    static async sendDailyDigestEmail(email: string, digest: any): Promise<void> {
        if (!this.isConnected || !this.transporter) await this.init();

        const trendsHtml = digest.topTrends.map((trend: any) => `
            <div style="margin-bottom: 20px; padding: 16px; background-color: #f8fafc; border-radius: 8px; border-left: 4px solid ${trend.severity === 'high' ? '#ef4444' : '#f59e0b'};">
                <h3 style="color: #0f172a; margin: 0 0 8px 0; font-size: 16px;">${trend.title}</h3>
                <p style="color: #475569; margin: 0; font-size: 14px; line-height: 20px;">${trend.description}</p>
                <div style="margin-top: 8px; font-size: 12px; color: #64748b;">
                    <strong>Reports:</strong> ${trend.reportCount} | <strong>Category:</strong> ${trend.category}
                </div>
            </div>
        `).join('');

        const mailOptions = {
            from: process.env.SMTP_FROM || '"FraudShield" <noreply@fraudshieldprotect.com>',
            to: email,
            subject: `Daily Scam Digest - ${digest.date}`,
            html: `
                <div style="font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
                    <div style="text-align: center; margin-bottom: 30px;">
                        <h1 style="color: #0f172a; margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.025em;">FraudShield</h1>
                        <p style="color: #64748b; margin-top: 4px; font-size: 14px;">Your Daily Scam Intelligence</p>
                    </div>
                    
                    <div style="margin-bottom: 30px;">
                        <h2 style="color: #0f172a; font-size: 18px; font-weight: 600; margin-bottom: 16px;">Daily Summary for ${digest.date}</h2>
                        <p style="color: #475569; font-size: 16px; line-height: 24px;">
                            Stay safe today. Here are the top scam trends detected in our community over the last 24 hours.
                        </p>
                        
                        <div style="background-color: #0f172a; color: #ffffff; border-radius: 8px; padding: 20px; margin: 24px 0; text-align: center;">
                            <div style="font-size: 12px; text-transform: uppercase; letter-spacing: 0.1em; opacity: 0.7; margin-bottom: 4px;">Total Scams Reported Today</div>
                            <div style="font-size: 32px; font-weight: 700;">${digest.totalReports}</div>
                        </div>

                        <div style="margin-top: 32px;">
                            <h3 style="color: #0f172a; font-size: 14px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 16px;">Top Trending Threats</h3>
                            ${trendsHtml}
                        </div>

                        <div style="margin-top: 32px; padding: 20px; background-color: #ecfdf5; border-radius: 8px; border: 1px solid #10b981;">
                            <h3 style="color: #065f46; margin: 0 0 8px 0; font-size: 16px;">💡 Safety Tip of the Day</h3>
                            <p style="color: #065f46; margin: 0; font-size: 14px; line-height: 20px;">${digest.safetyTip}</p>
                        </div>
                    </div>
                    
                    <div style="border-top: 1px solid #e2e8f0; padding-top: 24px; text-align: center;">
                        <p style="color: #94a3b8; font-size: 12px; margin-bottom: 8px;">
                            &copy; ${new Date().getFullYear()} FraudShield. All rights reserved.
                        </p>
                        <p style="color: #94a3b8; font-size: 10px;">
                            You received this email because you opted in to Daily Scam Digests. 
                            <a href="#" style="color: #3b82f6; text-decoration: none;">Manage preferences</a>
                        </p>
                    </div>
                </div>
            `,
        };

        try {
            await this.transporter!.sendMail(mailOptions);
            console.log(`📧 Daily Digest sent successfully to: ${email}`);
        } catch (error) {
            console.error('Failed to send daily digest email:', error);
        }
    }
}
