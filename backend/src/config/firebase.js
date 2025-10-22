const admin = require('firebase-admin');
const path = require('path');
const logger = require('../utils/logger');

let firebaseApp;

const initializeFirebase = () => {
  try {
    const serviceAccountPath = path.join(__dirname, 'firebase-admin-key.json');
    
    // Check if we're in development and file doesn't exist
    const fs = require('fs');
    if (!fs.existsSync(serviceAccountPath)) {
      logger.warn('Firebase admin key not found. Using test mode.');
      // For development without Firebase
      return null;
    }

    const serviceAccount = require(serviceAccountPath);

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: process.env.FIREBASE_PROJECT_ID,
    });

    logger.info('✅ Firebase Admin initialized successfully');
    return firebaseApp;
  } catch (error) {
    logger.error('❌ Firebase initialization failed:', error.message);
    return null;
  }
};

const verifyIdToken = async (idToken) => {
  try {
    if (!firebaseApp) {
      throw new Error('Firebase not initialized');
    }
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    logger.error('Token verification failed:', error.message);
    throw error;
  }
};

module.exports = {
  initializeFirebase,
  verifyIdToken,
  admin,
};
