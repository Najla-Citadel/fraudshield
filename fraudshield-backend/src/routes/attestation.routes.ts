import { Router } from 'express';
import { AttestationController } from '../controllers/attestation.controller';
import passport from '../config/passport';

const router = Router();

// Protect attestation routes with JWT
const authenticate = passport.authenticate('jwt', { session: false });

/**
 * @route   GET /api/v1/attestation/challenge
 * @desc    Generate a nonce for attestation
 * @access  Private
 */
router.get('/challenge', authenticate, AttestationController.getChallenge);

/**
 * @route   POST /api/v1/attestation/verify
 * @desc    Verify app integrity token
 * @access  Private
 */
router.post('/verify', authenticate, AttestationController.verify);

export default router;
