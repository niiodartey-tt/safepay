const express = require('express');
const router = express.Router();
const KYCController = require('../controllers/kycController');
const { authenticate } = require('../middleware/auth');

// All KYC routes require authentication
router.use(authenticate);

router.post('/submit', KYCController.submitKYC);
router.get('/documents', KYCController.getKYCDocuments);

module.exports = router;
