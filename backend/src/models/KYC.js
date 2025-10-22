const db = require('../config/database');

class KYC {
  static async submitDocument(userId, documentData) {
    const { documentType, documentUrl, documentNumber } = documentData;

    const query = `
      INSERT INTO kyc_documents (
        user_id,
        document_type,
        document_url,
        document_number
      )
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `;

    const values = [userId, documentType, documentUrl, documentNumber];
    const result = await db.query(query, values);
    return result.rows[0];
  }

  static async getUserDocuments(userId) {
    const query = `
      SELECT * FROM kyc_documents 
      WHERE user_id = $1 
      ORDER BY created_at DESC
    `;
    const result = await db.query(query, [userId]);
    return result.rows;
  }

  static async verifyDocument(documentId, verifiedBy) {
    const query = `
      UPDATE kyc_documents 
      SET 
        verified = TRUE,
        verified_by = $2,
        verified_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;

    const result = await db.query(query, [documentId, verifiedBy]);
    return result.rows[0];
  }

  static async rejectDocument(documentId, rejectionReason, verifiedBy) {
    const query = `
      UPDATE kyc_documents 
      SET 
        verified = FALSE,
        rejection_reason = $2,
        verified_by = $3,
        verified_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;

    const result = await db.query(query, [documentId, rejectionReason, verifiedBy]);
    return result.rows[0];
  }

  static async updateUserKYCStatus(userId, status) {
    const query = `
      UPDATE users 
      SET 
        kyc_status = $2,
        kyc_approved_at = CASE WHEN $2 = 'approved' THEN CURRENT_TIMESTAMP ELSE NULL END
      WHERE id = $1
      RETURNING *
    `;

    const result = await db.query(query, [userId, status]);
    return result.rows[0];
  }
}

module.exports = KYC;
