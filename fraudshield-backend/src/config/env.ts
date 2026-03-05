import logger from '../utils/logger';

/**
 * Validates that all required environment variables are present.
 * Throws an error and exits the process if any are missing.
 */
export const validateEnv = () => {
    const requiredEnvVars = [
        'JWT_SECRET',
        'JWT_REFRESH_SECRET',
        'DATABASE_URL',
        'OPENAI_API_KEY',
        'DB_ENCRYPTION_KEY',
    ];

    const optionalEnvVars = [
        'ADMIN_ALERT_EMAIL',
        'CRITICAL_ALERT_WEBHOOK_URL'
    ];

    const missingVars = requiredEnvVars.filter((varName) => !process.env[varName]);

    if (missingVars.length > 0) {
        const errorMsg = `❌ CRITICAL: Missing required environment variables: ${missingVars.join(', ')}`;
        logger.error(errorMsg);

        // In production, we must fail fast and loud.
        // In development, we still want to throw to alert the developer.
        throw new Error(errorMsg);
    }

    logger.info('✅ Environment variables validated');
};
