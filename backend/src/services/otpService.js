const db = require('../config/database');
const logger = require('../utils/logger');

class OTPService {
  // Generate 6-digit OTP
  static generateOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  // Store OTP in database
  static async createOTP(phoneNumber) {
    const otpCode = this.generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    const query = `
      INSERT INTO otp_verifications (phone_number, otp_code, expires_at)
      VALUES ($1, $2, $3)
      RETURNING id, otp_code, expires_at
    `;

    const result = await db.query(query, [phoneNumber, otpCode, expiresAt]);
    
    logger.info(`OTP generated for ${phoneNumber}: ${otpCode}`); // For development
    
    return result.rows[0];
  }

  // Verify OTP
  static async verifyOTP(phoneNumber, otpCode) {
    const query = `
      SELECT * FROM otp_verifications
      WHERE phone_number = $1 
        AND otp_code = $2 
        AND is_verified = FALSE
        AND expires_at > CURRENT_TIMESTAMP
      ORDER BY created_at DESC
      LIMIT 1
    `;

    const result = await db.query(query, [phoneNumber, otpCode]);

    if (result.rows.length === 0) {
      return { success: false, message: 'Invalid or expired OTP' };
    }

    // Mark OTP as verified
    const updateQuery = `
      UPDATE otp_verifications 
      SET is_verified = TRUE 
      WHERE id = $1
    `;
    await db.query(updateQuery, [result.rows[0].id]);

    return { success: true, message: 'OTP verified successfully' };
  }

  // Send OTP via SMS (placeholder - will integrate Twilio later)
  static async sendOTP(phoneNumber, otpCode) {
    // TODO: Integrate with Twilio or other SMS service
    logger.info(`📱 Sending OTP ${otpCode} to ${phoneNumber}`);
    
    // For development, just log it
    console.log(`\n🔐 OTP for ${phoneNumber}: ${otpCode}\n`);
    
    return { success: true, message: 'OTP sent successfully' };
  }

  // Clean up expired OTPs
  static async cleanupExpiredOTPs() {
    const query = 'DELETE FROM otp_verifications WHERE expires_at < CURRENT_TIMESTAMP';
    const result = await db.query(query);
    logger.info(`Cleaned up ${result.rowCount} expired OTPs`);
  }
}

module.exports = OTPService;
