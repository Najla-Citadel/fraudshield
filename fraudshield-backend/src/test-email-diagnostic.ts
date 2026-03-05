
import dotenv from 'dotenv';
import { EmailService } from './services/email.service';

dotenv.config();

async function runDiagnostic() {
    console.log('🔍 Starting Email Diagnostic...');
    console.log('-----------------------------------');
    console.log('SMTP Host:', process.env.SMTP_HOST);
    console.log('SMTP Port:', process.env.SMTP_PORT);
    console.log('SMTP User:', process.env.SMTP_USER);
    console.log('SMTP From:', process.env.SMTP_FROM);
    console.log('NODE_ENV:', process.env.NODE_ENV);
    console.log('-----------------------------------');

    try {
        await EmailService.init();
        console.log('✅ EmailService initialized.');

        const testEmail = 'karyuanfang.work@gmail.com'; // Using a real email for testing if possible, or a placeholder
        console.log(`🚀 Attempting to send OTP to: ${testEmail}...`);

        const otp = await EmailService.generatePasswordResetOtp(testEmail);
        console.log('✅ OTP Generated:', otp);
        console.log('✅ Diagnostic complete. Check console output above for any SMTP errors.');
    } catch (error: any) {
        console.error('❌ Diagnostic failed with error:');
        console.error(error);
        if (error.code) console.error('Error Code:', error.code);
        if (error.command) console.error('Error Command:', error.command);
    }
}

runDiagnostic().catch(console.error);
