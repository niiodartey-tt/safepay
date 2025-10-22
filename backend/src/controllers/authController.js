const User = require('../models/User');
const OTPService = require('../services/otpService');
const { generateAccessToken, generateRefreshToken } = require('../utils/jwt');
const logger = require('../utils/logger');

class AuthController {
  // Send OTP to phone number
  static async sendOTP(req, res, next) {
    try {
      const { phoneNumber } = req.body;

      if (!phoneNumber) {
        return res.status(400).json({
          success: false,
          message: 'Phone number is required',
        });
      }

      // Generate and store OTP
      const otp = await OTPService.createOTP(phoneNumber);
      
      // Send OTP via SMS
      await OTPService.sendOTP(phoneNumber, otp.otp_code);

      res.status(200).json({
        success: true,
        message: 'OTP sent successfully',
        data: {
          expiresAt: otp.expires_at,
        },
      });
    } catch (error) {
      logger.error('Send OTP error:', error);
      next(error);
    }
  }

  // Register new user
  static async register(req, res, next) {
    try {
      const { phoneNumber, email, userType, fullName, otpCode } = req.body;

      // Validate required fields
      if (!phoneNumber || !userType || !fullName || !otpCode) {
        return res.status(400).json({
          success: false,
          message: 'Phone number, user type, full name, and OTP are required',
        });
      }

      // Verify OTP
      const otpVerification = await OTPService.verifyOTP(phoneNumber, otpCode);
      if (!otpVerification.success) {
        return res.status(400).json({
          success: false,
          message: otpVerification.message,
        });
      }

      // Check if user already exists
      const existingUser = await User.findByPhoneNumber(phoneNumber);
      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: 'User with this phone number already exists',
        });
      }

      // Create user
      const user = await User.create({
        phoneNumber,
        email,
        userType,
        fullName,
      });

      // Generate tokens
      const accessToken = generateAccessToken(user.id, user.user_type);
      const refreshToken = generateRefreshToken(user.id);

      // Store refresh token
      await User.updateRefreshToken(user.id, refreshToken);

      logger.info(`New user registered: ${phoneNumber}`);

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
          user: {
            id: user.id,
            phoneNumber: user.phone_number,
            email: user.email,
            userType: user.user_type,
            fullName: user.full_name,
            walletBalance: user.wallet_balance,
          },
          accessToken,
          refreshToken,
        },
      });
    } catch (error) {
      logger.error('Registration error:', error);
      next(error);
    }
  }

  // Login existing user
  static async login(req, res, next) {
    try {
      const { phoneNumber, otpCode } = req.body;

      if (!phoneNumber || !otpCode) {
        return res.status(400).json({
          success: false,
          message: 'Phone number and OTP are required',
        });
      }

      // Verify OTP
      const otpVerification = await OTPService.verifyOTP(phoneNumber, otpCode);
      if (!otpVerification.success) {
        return res.status(400).json({
          success: false,
          message: otpVerification.message,
        });
      }

      // Find user
      const user = await User.findByPhoneNumber(phoneNumber);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found. Please register first.',
        });
      }

      // Generate tokens
      const accessToken = generateAccessToken(user.id, user.user_type);
      const refreshToken = generateRefreshToken(user.id);

      // Update last login and refresh token
      await User.updateRefreshToken(user.id, refreshToken);
      await User.updateLastLogin(user.id);

      logger.info(`User logged in: ${phoneNumber}`);

      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            id: user.id,
            phoneNumber: user.phone_number,
            email: user.email,
            userType: user.user_type,
            fullName: user.full_name,
            walletBalance: user.wallet_balance,
            isVerified: user.is_verified,
            kycStatus: user.kyc_status,
          },
          accessToken,
          refreshToken,
        },
      });
    } catch (error) {
      logger.error('Login error:', error);
      next(error);
    }
  }

  // Get current user profile
  static async getProfile(req, res, next) {
    try {
      const userId = req.user.userId;
      
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
        });
      }

      res.status(200).json({
        success: true,
        data: {
          user: {
            id: user.id,
            phoneNumber: user.phone_number,
            email: user.email,
            userType: user.user_type,
            fullName: user.full_name,
            walletBalance: user.wallet_balance,
            isVerified: user.is_verified,
            kycStatus: user.kyc_status,
            profilePhotoUrl: user.profile_photo_url,
            createdAt: user.created_at,
            lastLoginAt: user.last_login_at,
          },
        },
      });
    } catch (error) {
      logger.error('Get profile error:', error);
      next(error);
    }
  }
}

module.exports = AuthController;
