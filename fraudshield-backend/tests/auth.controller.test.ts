import request from 'supertest';
import app from '../src/app';
import { prisma } from '../src/config/database';
import { AuthService } from '../src/services/auth.service';

// ─── Mock Prisma ─────────────────────────────────────────────────────────────
const mockFindUnique = jest.fn();
const mockCreate = jest.fn();

jest.mock('../src/config/database', () => ({
    prisma: {
        user: {
            findUnique: (...args: any[]) => mockFindUnique(...args),
            create: (...args: any[]) => mockCreate(...args),
        },
        $queryRaw: jest.fn().mockResolvedValue([]),
    },
}));

// ─── Mock AuthService ─────────────────────────────────────────────────────────
jest.mock('../src/services/auth.service', () => ({
    AuthService: {
        hashPassword: jest.fn(),
        comparePasswords: jest.fn(),
        generateToken: jest.fn(),
        findUserById: jest.fn(),
        findUserByEmail: jest.fn(),
        toSafeUser: jest.fn(),
    },
}));

// ─── Mock Passport ────────────────────────────────────────────────────────────
jest.mock('../src/config/passport', () => ({
    __esModule: true,
    default: {
        initialize: () => (_req: any, _res: any, next: any) => next(),
        authenticate: (strategy: string, _options: any, callback?: Function) => {
            if (strategy === 'jwt') {
                return (_req: any, _res: any, next: any) => next();
            }
            return (_req: any, res: any, _next: any) => {
                if (callback) {
                    callback(null, false, { message: 'Invalid credentials' });
                } else {
                    res.status(401).json({ message: 'Invalid credentials' });
                }
            };
        },
    },
}));

// ─── Setup Mocks ──────────────────────────────────────────────────────────────
const mockAuthService = AuthService as unknown as {
    hashPassword: jest.Mock;
    generateToken: jest.Mock;
    toSafeUser: jest.Mock;
};

// ─── Sample data ──────────────────────────────────────────────────────────────
const validSignupBody = {
    email: 'test@example.com',
    password: 'Password1',
    fullName: 'Test User',
};

const mockCreatedUser = {
    id: 'user-id-1',
    email: 'test@example.com',
    fullName: 'Test User',
    passwordHash: 'hashed_password',
    role: 'USER',
    createdAt: new Date('2026-01-01'),
    profile: null,
};

// ─────────────────────────────────────────────────────────────────────────────
// SIGNUP TESTS
// ─────────────────────────────────────────────────────────────────────────────
describe('POST /api/v1/auth/signup', () => {
    beforeEach(() => {
        jest.clearAllMocks();

        // Setup default success behaviors
        mockFindUnique.mockResolvedValue(null);
        mockCreate.mockResolvedValue(mockCreatedUser);

        mockAuthService.hashPassword.mockResolvedValue('hashed_password');
        mockAuthService.generateToken.mockReturnValue('mock_jwt_token');
        mockAuthService.toSafeUser.mockImplementation((user: any) => ({
            id: user?.id ?? 'user-id-1',
            email: user?.email ?? 'test@example.com',
            fullName: user?.fullName ?? 'Test User',
            role: user?.role ?? 'USER',
            createdAt: '2026-01-01T00:00:00.000Z',
            isEmailVerified: true,
            profile: null,
        }));
    });

    it('✅ should create a new user and return 201 with token', async () => {
        const res = await request(app)
            .post('/api/v1/auth/signup')
            .send(validSignupBody);

        expect(res.status).toBe(201);
        expect(res.body).toHaveProperty('token', 'mock_jwt_token');
        expect(res.body).toHaveProperty('user');
        expect(res.body.user).toHaveProperty('email', 'test@example.com');
        expect(mockCreate).toHaveBeenCalledTimes(1);
    });

    it('✅ should sign up without optional fullName', async () => {
        const res = await request(app)
            .post('/api/v1/auth/signup')
            .send({ email: 'noname@example.com', password: 'Password1' });

        expect(res.status).toBe(201);
        expect(res.body).toHaveProperty('token');
    });

    it('❌ should return 400 if email is already in use', async () => {
        mockFindUnique.mockResolvedValue(mockCreatedUser);

        const res = await request(app)
            .post('/api/v1/auth/signup')
            .send(validSignupBody);

        expect(res.status).toBe(400);
        expect(res.body).toHaveProperty('message', 'Email already in use');
        expect(mockCreate).not.toHaveBeenCalled();
    });

    it('❌ should return 422 if email is missing', async () => {
        const res = await request(app)
            .post('/api/v1/auth/signup')
            .send({ password: 'Password1' });

        expect(res.status).toBe(422);
        expect(res.body.errors).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ field: 'email', message: 'Email is required.' }),
            ])
        );
    });

    it('❌ should return 422 if email format is invalid', async () => {
        const res = await request(app)
            .post('/api/v1/auth/signup')
            .send({ ...validSignupBody, email: 'not-an-email' });

        expect(res.status).toBe(422);
        expect(res.body.errors).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ field: 'email', message: 'Must be a valid email address.' }),
            ])
        );
    });

    it('❌ should return 422 if password is shorter than 8 characters', async () => {
        const res = await request(app)
            .post('/api/v1/auth/signup')
            .send({ ...validSignupBody, password: 'Pass1' });

        expect(res.status).toBe(422);
        expect(res.body.errors).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ field: 'password', message: 'Password must be at least 8 characters.' }),
            ])
        );
    });

    it('❌ should return 422 if password has no uppercase letter', async () => {
        const res = await request(app)
            .post('/api/v1/auth/signup')
            .send({ ...validSignupBody, password: 'password1' });

        expect(res.status).toBe(422);
        expect(res.body.errors).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ field: 'password', message: 'Password must contain at least one uppercase letter.' }),
            ])
        );
    });

    it('❌ should return 422 if password has no number', async () => {
        const res = await request(app)
            .post('/api/v1/auth/signup')
            .send({ ...validSignupBody, password: 'Password' });

        expect(res.status).toBe(422);
        expect(res.body.errors).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ field: 'password', message: 'Password must contain at least one number.' }),
            ])
        );
    });
});

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN TESTS
// ─────────────────────────────────────────────────────────────────────────────
describe('POST /api/v1/auth/login', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    it('❌ should return 422 if email is missing', async () => {
        const res = await request(app)
            .post('/api/v1/auth/login')
            .send({ password: 'Password1' });

        expect(res.status).toBe(422);
        expect(res.body.errors).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ field: 'email', message: 'Email is required.' }),
            ])
        );
    });

    it('❌ should return 422 if email format is invalid', async () => {
        const res = await request(app)
            .post('/api/v1/auth/login')
            .send({ email: 'bad-email', password: 'Password1' });

        expect(res.status).toBe(422);
        expect(res.body.errors).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ field: 'email', message: 'Must be a valid email address.' }),
            ])
        );
    });

    it('❌ should return 422 if password is missing', async () => {
        const res = await request(app)
            .post('/api/v1/auth/login')
            .send({ email: 'test@example.com' });

        expect(res.status).toBe(422);
        expect(res.body.errors).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ field: 'password', message: 'Password is required.' }),
            ])
        );
    });
});
