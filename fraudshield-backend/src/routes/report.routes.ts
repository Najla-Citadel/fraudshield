import { Router } from 'express';
import { ReportController } from '../controllers/report.controller';
import passport from 'passport';

const router = Router();

const authenticate = passport.authenticate('jwt', { session: false });

// Public routes
router.get('/search', ReportController.searchReports);
router.get('/public', ReportController.getPublicFeed);

// Protected routes
router.get('/lookup', authenticate, ReportController.lookupReport);
router.post('/', authenticate, ReportController.submitReport);
router.get('/my', authenticate, ReportController.getMyReports);
router.get('/:id', authenticate, ReportController.getReportDetails);
router.post('/verify', authenticate, ReportController.verifyReport);

export default router;
