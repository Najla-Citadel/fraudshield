import { Router } from 'express';
import { ReportController } from '../controllers/report.controller';
import { CommentController } from '../controllers/comment.controller';
import { ScamNumberController } from '../controllers/scam-number.controller';
import { authenticate } from '../middleware/auth.middleware';
import { validateReport } from '../middleware/validators';
import { reportLimiter, featureLimiter } from '../middleware/rateLimiter';
import { deviceFingerprint } from '../middleware/device-fingerprint';

const router = Router();

// Public routes
router.get('/search', ReportController.searchReports);
router.get('/public', ReportController.getPublicFeed);

// Protected routes
router.get('/lookup', authenticate, featureLimiter, ReportController.lookupReport);
router.post('/', authenticate, deviceFingerprint, reportLimiter, validateReport, ReportController.submitReport);
router.get('/my', authenticate, ReportController.getMyReports);
router.get('/:id', authenticate, ReportController.getReportDetails);
router.post('/verify', authenticate, featureLimiter, ReportController.verifyReport);
router.post('/lookup-feedback', authenticate, ReportController.submitLookupFeedback);
router.post('/flag-content', authenticate, featureLimiter, ReportController.flagContent);

// Comments
router.get('/:reportId/comments', CommentController.getComments);
router.post('/comments', authenticate, reportLimiter, CommentController.addComment);

// Scam number cache sync for offline protection
router.get('/scam-numbers/sync', authenticate, featureLimiter, ScamNumberController.syncScamNumbers);
router.get('/scam-numbers/stats', authenticate, ScamNumberController.getCacheStats);

export default router;
