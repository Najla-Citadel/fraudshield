import { Router } from 'express';
import { UploadController, upload } from '../controllers/upload.controller';
<<<<<<< HEAD
import passport from 'passport';
=======
import { authenticate } from '../middleware/auth.middleware';
>>>>>>> dev-ui2

const router = Router();

// Protect all upload routes
<<<<<<< HEAD
router.use(passport.authenticate('jwt', { session: false }));
=======
router.use(authenticate);
>>>>>>> dev-ui2

router.post('/single', upload.single('file'), UploadController.uploadFile);
router.post('/multiple', upload.array('files', 5), UploadController.uploadMultipleFiles);

export default router;
