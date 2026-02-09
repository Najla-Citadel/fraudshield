import { Router } from 'express';
import { ReportController } from '../controllers/report.controller';
import passport from 'passport';

const router = Router();

// All report routes are protected
router.use(passport.authenticate('jwt', { session: false }));

router.post('/', ReportController.submitReport);
router.get('/', ReportController.getMyReports);
router.get('/:id', ReportController.getReportDetails);

export default router;
