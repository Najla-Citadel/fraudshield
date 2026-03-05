import { Request, Response } from 'express';
import { VoiceSignalController } from '../src/controllers/voice-signal.controller';
import * as redisModule from '../src/config/redis';
import logger from '../src/utils/logger';

// 1. Mock the modules
jest.mock('../src/config/redis');
jest.mock('../src/utils/logger', () => ({
    __esModule: true,
    info: jest.fn(),
    error: jest.fn(),
    default: {
        info: jest.fn(),
        error: jest.fn(),
    }
}));

// 2. Get the mocked versions
const mockedGetRedisClient = jest.mocked(redisModule.getRedisClient);
const mockedLogger = jest.mocked(logger);

describe('VoiceSignalController', () => {
    let mockRequest: Partial<Request>;
    let mockResponse: Partial<Response>;
    let next: jest.Mock;
    let mockRedis: any;

    beforeEach(() => {
        jest.clearAllMocks();

        // Setup Redis mock
        mockRedis = {
            set: jest.fn().mockResolvedValue('OK'),
        };
        mockedGetRedisClient.mockReturnValue(mockRedis);

        mockRequest = {
            user: { id: 'user-123' },
            body: {},
        };
        mockResponse = {
            status: jest.fn().mockReturnThis(),
            send: jest.fn().mockReturnThis(),
        };
        next = jest.fn();
    });

    it('successfully stores inContacts flag on CALL_START', async () => {
        mockRequest.body = {
            event: 'CALL_START',
            incomingNumber: '0123456789',
            inContacts: true
        };

        await VoiceSignalController.reportCallSignal(
            mockRequest as Request,
            mockResponse as Response,
            next
        );

        expect(mockResponse.status).toHaveBeenCalledWith(204);
        expect(mockRedis.set).toHaveBeenCalledWith(
            'macau_signal:voice:user-123',
            expect.stringContaining('"inContacts":true'),
            'EX',
            3600
        );
        expect(mockedLogger.info).toHaveBeenCalledWith(expect.stringContaining('inContacts: true'));
    });

    it('defaults inContacts to false if not provided', async () => {
        mockRequest.body = {
            event: 'CALL_START',
            incomingNumber: '0123456789'
        };

        await VoiceSignalController.reportCallSignal(
            mockRequest as Request,
            mockResponse as Response,
            next
        );

        expect(mockRedis.set).toHaveBeenCalledWith(
            'macau_signal:voice:user-123',
            expect.stringContaining('"inContacts":false'),
            'EX',
            3600
        );
    });

    it('stores duration and inContacts on CALL_ENDED', async () => {
        mockRequest.body = {
            event: 'CALL_ENDED',
            duration: 120,
            inContacts: false
        };

        await VoiceSignalController.reportCallSignal(
            mockRequest as Request,
            mockResponse as Response,
            next
        );

        expect(mockResponse.status).toHaveBeenCalledWith(204);
        expect(mockRedis.set).toHaveBeenCalledWith(
            'macau_signal:voice:user-123',
            expect.stringContaining('"durationSeconds":120'),
            'EX',
            1800
        );
        expect(mockedLogger.info).toHaveBeenCalledWith(expect.stringContaining('Duration: 120s, inContacts: false'));
    });
});
