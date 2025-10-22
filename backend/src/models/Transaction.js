const db = require('../config/database');

class Transaction {
  static async create(transactionData) {
    const {
      transactionRef,
      buyerId,
      sellerId,
      riderId,
      amount,
      commission,
      totalAmount,
      transactionType,
      itemDescription,
      itemCategory,
      deliveryAddress,
      paymentMethod,
      notes,
    } = transactionData;

    const query = `
      INSERT INTO transactions (
        transaction_ref,
        buyer_id,
        seller_id,
        rider_id,
        amount,
        commission,
        total_amount,
        transaction_type,
        item_description,
        item_category,
        delivery_address,
        payment_method,
        notes,
        status
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, 'pending')
      RETURNING *
    `;

    const values = [
      transactionRef,
      buyerId,
      sellerId,
      riderId,
      amount,
      commission,
      totalAmount,
      transactionType,
      itemDescription,
      itemCategory,
      deliveryAddress,
      paymentMethod,
      notes,
    ];

    const result = await db.query(query, values);
    return result.rows[0];
  }

  static async findById(id) {
    const query = `
      SELECT 
        t.*,
        b.full_name as buyer_name,
        b.phone_number as buyer_phone,
        s.full_name as seller_name,
        s.phone_number as seller_phone,
        r.full_name as rider_name,
        r.phone_number as rider_phone
      FROM transactions t
      LEFT JOIN users b ON t.buyer_id = b.id
      LEFT JOIN users s ON t.seller_id = s.id
      LEFT JOIN users r ON t.rider_id = r.id
      WHERE t.id = $1
    `;
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  static async findByRef(transactionRef) {
    const query = 'SELECT * FROM transactions WHERE transaction_ref = $1';
    const result = await db.query(query, [transactionRef]);
    return result.rows[0];
  }

  static async findByUserId(userId, role = null) {
    let query = `
      SELECT 
        t.*,
        b.full_name as buyer_name,
        s.full_name as seller_name,
        r.full_name as rider_name
      FROM transactions t
      LEFT JOIN users b ON t.buyer_id = b.id
      LEFT JOIN users s ON t.seller_id = s.id
      LEFT JOIN users r ON t.rider_id = r.id
      WHERE 
    `;

    if (role === 'buyer') {
      query += 't.buyer_id = $1';
    } else if (role === 'seller') {
      query += 't.seller_id = $1';
    } else if (role === 'rider') {
      query += 't.rider_id = $1';
    } else {
      query += '(t.buyer_id = $1 OR t.seller_id = $1 OR t.rider_id = $1)';
    }

    query += ' ORDER BY t.created_at DESC';

    const result = await db.query(query, [userId]);
    return result.rows;
  }

  static async updateStatus(transactionId, newStatus, changedBy, reason = null) {
    const client = await db.pool.connect();

    try {
      await client.query('BEGIN');

      // Get current status
      const currentTransaction = await client.query(
        'SELECT status FROM transactions WHERE id = $1',
        [transactionId]
      );

      const oldStatus = currentTransaction.rows[0].status;

      // Update transaction status
      const updateQuery = `
        UPDATE transactions 
        SET status = $1, updated_at = CURRENT_TIMESTAMP 
        WHERE id = $2 
        RETURNING *
      `;
      const updateResult = await client.query(updateQuery, [newStatus, transactionId]);

      // Insert status history
      await client.query(
        `INSERT INTO transaction_status_history 
         (transaction_id, old_status, new_status, changed_by, reason) 
         VALUES ($1, $2, $3, $4, $5)`,
        [transactionId, oldStatus, newStatus, changedBy, reason]
      );

      await client.query('COMMIT');
      return updateResult.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async getStatusHistory(transactionId) {
    const query = `
      SELECT 
        tsh.*,
        u.full_name as changed_by_name
      FROM transaction_status_history tsh
      LEFT JOIN users u ON tsh.changed_by = u.id
      WHERE tsh.transaction_id = $1
      ORDER BY tsh.created_at ASC
    `;
    const result = await db.query(query, [transactionId]);
    return result.rows;
  }

  static generateTransactionRef() {
    const timestamp = Date.now().toString(36);
    const randomStr = Math.random().toString(36).substring(2, 8);
    return `TXN-${timestamp}-${randomStr}`.toUpperCase();
  }
}

module.exports = Transaction;
