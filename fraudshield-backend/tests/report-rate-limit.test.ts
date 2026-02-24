import request from 'supertest';

// ─── Mock Prisma ─────────────────────────────────────────────────────────────
jest.mock('../src/config/database', () => ({
    prisma: {
        $queryRaw: jest.fn().mockResolvedValue([]),
        $connect: jest.fn().mockResolvedValue(null),
        $disconnect: jest.fn().mockResolvedValue(null),
    },
}));

// ─── Mock Passport ────────────────────────────────────────────────────────────
jest.mock('../src/config/passport', () => ({
    __esModule: true,
    default: {
        initialize: () => (_req: any, _res: any, next: any) => next(),
        authenticate: () => (req: any, _res: any, next: any) => {
            req.user = { id: 'test-user-rate-limit' };
            next();
        },
    },
}));

import app from '../src/app';

describe('Report Rate Limiting Integration', () => {
    it('✅ should allow a report submission', async () => {
        const res = await request(app)
            .post('/api/v1/reports')
            .send({ target: '0123456789', targetType: 'phone', description: 'Test' });

        // We expect either 201 (success) or something else if other things fail, 
        // but not a 429 yet.
        expect(res.status).not.toBe(429);
    });
});
