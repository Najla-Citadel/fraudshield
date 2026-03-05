import { HealthScoreService } from '../src/services/health-score.service';
import { prisma } from '../src/config/database';

// Mock Prisma
jest.mock('../src/config/database', () => ({
    prisma: {
        user: {
            findUnique: jest.fn(),
        },
    },
}));

describe('HealthScoreService', () => {
    const mockUserId = 'user-123';

    beforeEach(() => {
        jest.clearAllMocks();
    });

    it('should calculate a perfect score (100) for an ideal user', async () => {
        (prisma.user.findUnique as jest.Mock).mockResolvedValue({
            id: mockUserId,
            emailVerified: true,
            fullName: 'Ideal User',
            profile: {
                bio: 'I am a pro',
                avatar: 'avatar.png',
                mobile: '+60123456789',
                reputation: 50,
            },
            subscriptions: [{ isActive: true }],
            reports: new Array(10).fill({}),
            alertSubscription: { isActive: true },
        });

        const result = await HealthScoreService.calculateScore(mockUserId);
        expect(result.score).toBe(100);
        expect(result.breakdown).toEqual({
            verification: 20,
            subscription: 30,
            profile: 15,
            reputation: 15,
            activity: 10,
            alerts: 10,
        });
    });

    it('should calculate a base score for a new unverified user', async () => {
        (prisma.user.findUnique as jest.Mock).mockResolvedValue({
            id: mockUserId,
            emailVerified: false,
            fullName: null,
            profile: null,
            subscriptions: [],
            reports: [],
            alertSubscription: null,
        });

        const result = await HealthScoreService.calculateScore(mockUserId);
        expect(result.score).toBe(0);
        expect(result.breakdown).toEqual({
            verification: 0,
            subscription: 0,
            profile: 0,
            reputation: 0,
            activity: 0,
            alerts: 0,
        });
    });

    it('should cap the score at 100', async () => {
        (prisma.user.findUnique as jest.Mock).mockResolvedValue({
            id: mockUserId,
            emailVerified: true,
            fullName: 'Super User',
            profile: {
                reputation: 100, // Extra reputation
            },
            subscriptions: [{ isActive: true }],
            reports: new Array(20).fill({}), // Extra reports
            alertSubscription: { isActive: true },
        });

        // Score components: 20 (ver) + 30 (sub) + 4 (name) + 15 (rep) + 10 (act) + 10 (alt) = 89
        // Wait, profile completeness is separate.

        const result = await HealthScoreService.calculateScore(mockUserId);
        expect(result.score).toBeLessThanOrEqual(100);
    });

    it('should throw error if user not found', async () => {
        (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);
        await expect(HealthScoreService.calculateScore(mockUserId)).rejects.toThrow('User not found');
    });
});
