import request from 'supertest';
import { AuthService } from '../src/services/auth.service';

describe('Security Hardening Verification', () => {
    let app: any;
    const originalEnv = process.env;

    // Define mock functions at the describe level (must be prefixed with mock for hoisting if used in jest.mock)
    const mockExists = jest.fn();
    const mockSetex = jest.fn();
    const mockCall = jest.fn().mockResolvedValue('OK');

    beforeAll(() => {
        process.env = { ...originalEnv };
        process.env.NODE_ENV = 'test';
        process.env.METRICS_API_KEY = 'test-key';
        process.env.TURNSTILE_SECRET_KEY = 'test-key';

        // Mock Redis before requiring app
        jest.mock('../src/config/redis', () => ({
            getRedisClient: jest.fn(() => ({
                exists: mockExists,
                setex: mockSetex,
                call: mockCall,
            }))
        }));

        // Require app after mocking
        app = require('../src/app').default;
    });

    afterAll(() => {
        process.env = originalEnv;
    });

    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('Metrics Protection', () => {
        it('should return 401 if METRICS_API_KEY is missing in request', async () => {
            process.env.METRICS_API_KEY = 'secret-key';
            const res = await request(app).get('/metrics');
            expect(res.status).toBe(401);
            expect(res.body.error).toBe('Unauthorized');
        });

        it('should return 401 if METRICS_API_KEY is incorrect', async () => {
            process.env.METRICS_API_KEY = 'secret-key';
            const res = await request(app)
                .get('/metrics')
                .set('x-metrics-api-key', 'wrong-key');
            expect(res.status).toBe(401);
        });

        it('should return 200 if METRICS_API_KEY is correct (header)', async () => {
            process.env.METRICS_API_KEY = 'secret-key';
            const res = await request(app)
                .get('/metrics')
                .set('x-metrics-api-key', 'secret-key');
            expect(res.status).not.toBe(401);
        });
    });

    describe('Anti-Replay Fail-Closed', () => {
        it('should return 503 if Redis fails and fail-open is NOT enabled', async () => {
            mockExists.mockRejectedValue(new Error('Redis connection lost'));
            
            const res = await request(app)
                .post('/api/v1/reports')
                .set('x-fs-timestamp', Date.now().toString())
                .set('x-fs-nonce', 'test-nonce');
            
            expect(res.status).toBe(503);
            expect(res.body.code).toBe('SECURITY_SERVICE_OFFLINE');
        });

        it('should fail-open (call next) if Redis fails and ANTI_REPLAY_FAIL_OPEN is true', async () => {
            mockExists.mockRejectedValue(new Error('Redis connection lost'));
            process.env.ANTI_REPLAY_FAIL_OPEN = 'true';

            const res = await request(app)
                .post('/api/v1/reports')
                .set('x-fs-timestamp', Date.now().toString())
                .set('x-fs-nonce', 'test-nonce');
            
            expect(res.status).not.toBe(503);
        });
    });

    describe('CAPTCHA Hardening', () => {
        it('should return false if TURNSTILE_SECRET_KEY is missing and NOT in development', async () => {
            process.env.NODE_ENV = 'production';
            delete process.env.TURNSTILE_SECRET_KEY;
            
            const result = await AuthService.verifyCaptcha('some-token');
            expect(result).toBe(false);
        });

        it('should return true if TURNSTILE_SECRET_KEY is missing but IN development', async () => {
            process.env.NODE_ENV = 'development';
            delete process.env.TURNSTILE_SECRET_KEY;
            
            const result = await AuthService.verifyCaptcha('some-token');
            expect(result).toBe(true);
        });
    });
});
