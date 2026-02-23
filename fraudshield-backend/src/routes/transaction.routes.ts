import { Router } from 'express';
import { TransactionController } from '../controllers/transaction.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Protect all transaction routes
router.use(authenticate);

// Get summary list of the journal
router.get('/', TransactionController.getMyTransactions);

// Manually log a transaction
router.post('/', TransactionController.logTransaction);

// Get deep dive details of a specific scan
router.get('/:id', TransactionController.getTransactionDetails);

// Convert a transaction to a scam report
router.post('/:id/report', TransactionController.convertToReport);

export default router;
