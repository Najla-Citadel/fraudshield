// fraudshield-backend/tests/email.service.test.ts
import { EmailService } from '../src/services/email.service';
import { createClient } from 'redis';
import nodemailer from 'nodemailer';

jest.mock('nodemailer');
const mockedNodemailer = nodemailer as jest.Mocked<typeof nodemailer>;

describe('EmailService', () => {
    let mockTransporter: any;

    beforeAll(async () => {
        mockTransporter = {
            sendMail: jest.fn().mockResolvedValue({ messageId: 'test-id' }),
        };
        mockedNodemailer.createTransport.mockReturnValue(mockTransporter);

        // Ensure EmailService is initialized
        await EmailService.init();
    });

    afterAll(async () => {
        // Clean up Redis if possible, though here we use the real redis if running
    });

    it('should generate a 6-digit OTP and store it in Redis', async () => {
        const email = 'test@example.com';
        const otp = await EmailService.generatePasswordResetOtp(email);

        expect(otp).toHaveLength(6);
        expect(Number(otp)).toBeGreaterThanOrEqual(100000);
        expect(Number(otp)).toBeLessThanOrEqual(999999);

        // Verify email was "sent" (mocked)
        expect(mockTransporter.sendMail).toHaveBeenCalledWith(expect.objectContaining({
            to: email,
            subject: 'Password Reset Code - FraudShield',
        }));
    });

    it('should verify a valid OTP', async () => {
        const email = 'verify@example.com';
        const otp = await EmailService.generatePasswordResetOtp(email);

        const isValid = await EmailService.verifyPasswordResetOtp(email, otp);
        expect(isValid).toBe(true);
    });

    it('should not verify an invalid OTP', async () => {
        const email = 'invalid@example.com';
        await EmailService.generatePasswordResetOtp(email);

        const isValid = await EmailService.verifyPasswordResetOtp(email, '000000');
        expect(isValid).toBe(false);
    });

    it('should not verify an OTP twice (it should be deleted after verification)', async () => {
        const email = 'twice@example.com';
        const otp = await EmailService.generatePasswordResetOtp(email);

        const isValidFirst = await EmailService.verifyPasswordResetOtp(email, otp);
        expect(isValidFirst).toBe(true);

        const isValidSecond = await EmailService.verifyPasswordResetOtp(email, otp);
        expect(isValidSecond).toBe(false);
    });
});
