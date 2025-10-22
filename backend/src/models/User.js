const db = require('../config/database');
const bcrypt = require('bcryptjs');

class User {
  static async create(userData) {
    const {
      phoneNumber,
      email,
      userType,
      fullName,
      password,
      firebaseUid,
    } = userData;

    const passwordHash = password ? await bcrypt.hash(password, 10) : null;

    const query = `
      INSERT INTO users (
        phone_number, 
        email, 
        user_type, 
        full_name, 
        password_hash,
        firebase_uid
      )
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING 
        id, 
        phone_number, 
        email, 
        user_type, 
        full_name, 
        wallet_balance,
        is_verified,
        created_at
    `;

    const values = [phoneNumber, email, userType, fullName, passwordHash, firebaseUid];
    const result = await db.query(query, values);
    return result.rows[0];
  }

  static async findByPhoneNumber(phoneNumber) {
    const query = 'SELECT * FROM users WHERE phone_number = $1';
    const result = await db.query(query, [phoneNumber]);
    return result.rows[0];
  }

  static async findById(id) {
    const query = `
      SELECT 
        id, 
        phone_number, 
        email, 
        user_type, 
        full_name, 
        wallet_balance,
        is_verified,
        kyc_status,
        profile_photo_url,
        created_at,
        last_login_at
      FROM users 
      WHERE id = $1
    `;
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  static async findByFirebaseUid(firebaseUid) {
    const query = 'SELECT * FROM users WHERE firebase_uid = $1';
    const result = await db.query(query, [firebaseUid]);
    return result.rows[0];
  }

  static async updateLastLogin(userId) {
    const query = 'UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1';
    await db.query(query, [userId]);
  }

  static async updateRefreshToken(userId, refreshToken) {
    const query = 'UPDATE users SET refresh_token = $1 WHERE id = $2';
    await db.query(query, [refreshToken, userId]);
  }

  static async verifyPassword(phoneNumber, password) {
    const user = await this.findByPhoneNumber(phoneNumber);
    if (!user || !user.password_hash) {
      return null;
    }

    const isValid = await bcrypt.compare(password, user.password_hash);
    return isValid ? user : null;
  }

  static async updateKYC(userId, kycData) {
    const {
      idCardUrl,
      idCardNumber,
      profilePhotoUrl,
      address,
      dateOfBirth,
    } = kycData;

    const query = `
      UPDATE users 
      SET 
        id_card_url = $1,
        id_card_number = $2,
        profile_photo_url = $3,
        address = $4,
        date_of_birth = $5,
        kyc_status = 'pending',
        kyc_submitted_at = CURRENT_TIMESTAMP
      WHERE id = $6
      RETURNING *
    `;

    const values = [idCardUrl, idCardNumber, profilePhotoUrl, address, dateOfBirth, userId];
    const result = await db.query(query, values);
    return result.rows[0];
  }
}

module.exports = User;
