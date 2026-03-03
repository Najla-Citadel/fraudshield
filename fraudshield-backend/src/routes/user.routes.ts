import { Router } from 'express';
import { UserController } from '../controllers/user.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Protected routes
<<<<<<< HEAD
=======
router.get('/security-health', authenticate, UserController.getSecurityHealth);
>>>>>>> dev-ui2
router.get('/export', authenticate, UserController.exportData);
router.post('/consent/terms', authenticate, UserController.updateTermsConsent);
router.delete('/me', authenticate, UserController.deleteAccount);

export default router;
