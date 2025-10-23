const express = require('express');
const router = express.Router();
const EscrowController = require('../controllers/escrowController');
const { authenticate } = require('../middleware/auth');

// All escrow routes require authentication
router.use(authenticate);

// Transaction management
router.post('/transaction/create', EscrowController.createEscrowTransaction);
router.get('/transaction/:transactionId', EscrowController.getTransaction);
router.get('/transactions', EscrowController.getUserTransactions);
router.put('/transaction/:transactionId/status', EscrowController.updateTransactionStatus);

// Delivery actions
router.post('/transaction/:transactionId/confirm-delivery', EscrowController.confirmDelivery);
router.post('/transaction/:transactionId/reject-delivery', EscrowController.rejectDelivery);

module.exports = router;
