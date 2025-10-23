const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const logger = require('./utils/logger');
const errorHandler = require('./middleware/errorHandler');
const { initializeFirebase } = require('./config/firebase');

// Import routes
const healthRoutes = require('./routes/health');
const authRoutes = require('./routes/auth');
const kycRoutes = require('./routes/kyc');
const escrowRoutes = require('./routes/escrow');

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Firebase (optional for now)
initializeFirebase();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Routes
app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/kyc', kycRoutes);
app.use('/api/escrow', escrowRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to SafePay Ghana API',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      auth: {
        sendOTP: 'POST /api/auth/send-otp',
        register: 'POST /api/auth/register',
        login: 'POST /api/auth/login',
        profile: 'GET /api/auth/profile',
      },
      kyc: {
        submit: 'POST /api/kyc/submit',
        documents: 'GET /api/kyc/documents',
      },
      escrow: {
        createTransaction: 'POST /api/escrow/transaction/create',
        getTransaction: 'GET /api/escrow/transaction/:transactionId',
        getTransactions: 'GET /api/escrow/transactions',
        confirmDelivery: 'POST /api/escrow/transaction/:transactionId/confirm-delivery',
        rejectDelivery: 'POST /api/escrow/transaction/:transactionId/reject-delivery',
        updateStatus: 'PUT /api/escrow/transaction/:transactionId/status',
      },
    },
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

// Error handling middleware
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  logger.info(`🚀 SafePay Ghana Backend running on port ${PORT}`);
  logger.info(`📍 Environment: ${process.env.NODE_ENV}`);
  logger.info(`🔗 API: http://localhost:${PORT}`);
});

module.exports = app;
