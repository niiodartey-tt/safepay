const express = require('express');
const router = express.Router();
const db = require('../config/database');

// Health check endpoint
router.get('/', async (req, res) => {
  try {
    // Test database connection
    await db.query('SELECT NOW()');
    
    res.status(200).json({
      success: true,
      message: 'SafePay Ghana API is running',
      timestamp: new Date().toISOString(),
      database: 'connected',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Database connection failed',
      error: error.message,
    });
  }
});

module.exports = router;
