const db = require('../config/database');

class Escrow {
  static async create(transactionId, amount) {
    const escrowRef = this.generateEscrowRef();

    const query = `
      INSERT INTO escrow_accounts (
        transaction_id,
        escrow_ref,
        amount,
        status
      )
      VALUES ($1, $2, $3, 'held')
      RETURNING *
    `;

    const values = [transactionId, escrowRef, amount];
    const result = await db.query(query, values);
    return result.rows[0];
  }

  static async findByTransactionId(transactionId) {
    const query = 'SELECT * FROM escrow_accounts WHERE transaction_id = $1';
    const result = await db.query(query, [transactionId]);
    return result.rows[0];
  }

  static async findByRef(escrowRef) {
    const query = 'SELECT * FROM escrow_accounts WHERE escrow_ref = $1';
    const result = await db.query(query, [escrowRef]);
    return result.rows[0];
  }

  static async release(transactionId, reason = null) {
    const query = `
      UPDATE escrow_accounts 
      SET 
        status = 'released',
        released_at = CURRENT_TIMESTAMP,
        release_reason = $2,
        updated_at = CURRENT_TIMESTAMP
      WHERE transaction_id = $1
      RETURNING *
    `;

    const result = await db.query(query, [transactionId, reason]);
    return result.rows[0];
  }

  static async refund(transactionId, reason = null) {
    const query = `
      UPDATE escrow_accounts 
      SET 
        status = 'refunded',
        refunded_at = CURRENT_TIMESTAMP,
        refund_reason = $2,
        updated_at = CURRENT_TIMESTAMP
      WHERE transaction_id = $1
      RETURNING *
    `;

    const result = await db.query(query, [transactionId, reason]);
    return result.rows[0];
  }

  static generateEscrowRef() {
    const timestamp = Date.now().toString(36);
    const randomStr = Math.random().toString(36).substring(2, 8);
    return `ESC-${timestamp}-${randomStr}`.toUpperCase();
  }
}

module.exports = Escrow;
