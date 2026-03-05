import request from 'supertest';
import app from '../../src/app';
import { prisma } from '../../src/config/database';

// ─── Mock Prisma ─────────────────────────────────────────────────────────────
const mockUserFindMany = jest.fn();
const mockUserUpdate = jest.fn();
const mockScamReportFindMany = jest.fn();
const mockScamReportUpdate = jest.fn();
const mockUserCount = jest.fn();
const mockScamReportCount = jest.fn();

jest.mock('../../src/config/database', () => ({
    prisma: {
        user: {
            findMany: (...args: any[]) => mockUserFindMany(...args),
            update: (...args: any[]) => mockUserUpdate(...args),
            count: (...args: any[]) => mockUserCount(...args),
        },
        scamReport: {
            findMany: (...args: any[]) => mockScamReportFindMany(...args),
            update: (...args: any[]) => mockScamReportUpdate(...args),
            count: (...args: any[]) => mockScamReportCount(...args),
        },
    },
}));

// ─── Mock Passport & isAdmin Middleware ──────────────────────────────────────
// ─── Mock Passport & isAdmin Middleware ──────────────────────────────────────
jest.mock('passport', () => ({
    initialize: () => (_req: any, _res: any, next: any) => next(),
    authenticate: (strategy: string, _options: any, callback?: Function) => {
        return (_req: any, _res: any, next: any) => {
            _req.user = { id: 'admin-1', role: 'admin', emailVerified: true };
            next();
        };
    },
    use: jest.fn(),
}));

jest.mock('../../src/config/passport', () => ({
    __esModule: true,
    default: {
        initialize: () => (_req: any, _res: any, next: any) => next(),
        authenticate: (strategy: string, _options: any, callback?: Function) => {
            return (_req: any, _res: any, next: any) => {
                _req.user = { id: 'admin-1', role: 'admin', emailVerified: true };
                next();
            };
        },
        use: jest.fn(),
    },
}));

jest.mock('../../src/middleware/admin.middleware', () => ({
    isAdmin: (_req: any, _res: any, next: any) => next(),
}));

describe('Admin Management Integration Tests', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('GET /api/v1/admin/stats', () => {
        it('should return system statistics', async () => {
            mockUserCount.mockResolvedValue(10);
            mockScamReportCount
                .mockResolvedValueOnce(5)  // total reports
                .mockResolvedValueOnce(2);  // pending

            const res = await request(app).get('/api/v1/admin/stats');

            expect(res.status).toBe(200);
            expect(res.body).toEqual({
                totalUsers: 10,
                totalReports: 5,
                pendingReports: 2,
            });
        });
    });

    describe('GET /api/v1/admin/users', () => {
        it('should return a list of users', async () => {
            const mockUsers = [
                { id: '1', email: 'u1@ex.com', role: 'user' },
                { id: '2', email: 'u2@ex.com', role: 'admin' },
            ];
            mockUserFindMany.mockResolvedValue(mockUsers);

            const res = await request(app).get('/api/v1/admin/users');

            expect(res.status).toBe(200);
            expect(res.body).toHaveLength(2);
            expect(res.body[0].email).toBe('u1@ex.com');
        });
    });

    describe('PATCH /api/v1/admin/users/:id/role', () => {
        it('should update user role', async () => {
            mockUserUpdate.mockResolvedValue({ id: '1', role: 'admin' });

            const res = await request(app)
                .patch('/api/v1/admin/users/1/role')
                .send({ role: 'admin' });

            expect(res.status).toBe(200);
            expect(res.body.role).toBe('admin');
            expect(mockUserUpdate).toHaveBeenCalledWith(expect.objectContaining({
                where: { id: '1' },
                data: { role: 'admin' }
            }));
        });
    });
});
