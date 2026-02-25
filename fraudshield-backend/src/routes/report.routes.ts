import { Router } from 'express';
import { ReportController } from '../controllers/report.controller';
import { CommentController } from '../controllers/comment.controller';
import passport from 'passport';
import { validateReport } from '../middleware/validators';
import { reportLimiter } from '../middleware/rateLimiter';

const router = Router();

const authenticate = passport.authenticate('jwt', { session: false });

// Public routes
router.get('/search', ReportController.searchReports);
router.get('/public', ReportController.getPublicFeed);

// Protected routes
router.get('/lookup', authenticate, ReportController.lookupReport);
router.post('/', authenticate, reportLimiter, validateReport, ReportController.submitReport);
router.get('/my', authenticate, ReportController.getMyReports);
router.get('/:id', authenticate, ReportController.getReportDetails);
router.post('/verify', authenticate, ReportController.verifyReport);

// Comments
router.get('/:reportId/comments', CommentController.getComments);
router.post('/comments', authenticate, CommentController.addComment);

export default router;
