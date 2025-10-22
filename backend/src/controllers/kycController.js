const KYC = require('../models/KYC');
const User = require('../models/User');
const logger = require('../utils/logger');

class KYCController {
  // Submit KYC documents
  static async submitKYC(req, res, next) {
    try {
      const userId = req.user.userId;
      const {
        idCardUrl,
        idCardNumber,
        profilePhotoUrl,
        address,
        dateOfBirth,
      } = req.body;

      // Validate required fields
      if (!idCardUrl || !idCardNumber || !profilePhotoUrl) {
        return res.status(400).json({
          success: false,
          message: 'ID card, ID number, and profile photo are required',
        });
      }

      // Submit ID card document
      await KYC.submitDocument(userId, {
        documentType: 'id_card',
        documentUrl: idCardUrl,
        documentNumber: idCardNumber,
      });

      // Submit profile photo
      await KYC.submitDocument(userId, {
        documentType: 'profile_photo',
        documentUrl: profilePhotoUrl,
        documentNumber: null,
      });

      // Update user KYC info
      const updatedUser = await User.updateKYC(userId, {
        idCardUrl,
        idCardNumber,
        profilePhotoUrl,
        address,
        dateOfBirth,
      });

      logger.info(`KYC submitted for user: ${userId}`);

      res.status(200).json({
        success: true,
        message: 'KYC documents submitted successfully',
        data: {
          kycStatus: updatedUser.kyc_status,
          submittedAt: updatedUser.kyc_submitted_at,
        },
      });
    } catch (error) {
      logger.error('Submit KYC error:', error);
      next(error);
    }
  }

  // Get user's KYC documents
  static async getKYCDocuments(req, res, next) {
    try {
      const userId = req.user.userId;

      const documents = await KYC.getUserDocuments(userId);
      const user = await User.findById(userId);

      res.status(200).json({
        success: true,
        data: {
          kycStatus: user.kyc_status,
          submittedAt: user.kyc_submitted_at,
          approvedAt: user.kyc_approved_at,
          documents,
        },
      });
    } catch (error) {
      logger.error('Get KYC documents error:', error);
      next(error);
    }
  }
}

module.exports = KYCController;
