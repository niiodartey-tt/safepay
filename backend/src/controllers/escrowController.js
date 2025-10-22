const Transaction = require('../models/Transaction');
const Escrow = require('../models/Escrow');
const User = require('../models/User');
const db = require('../config/database');
const logger = require('../utils/logger');

class EscrowController {
  // Create new escrow transaction
  static async createEscrowTransaction(req, res, next) {
    const client = await db.pool.connect();

    try {
      const buyerId = req.user.userId;
      const {
        sellerId,
        amount,
        itemDescription,
        itemCategory,
        deliveryAddress,
        riderId,
        notes,
      } = req.body;

      // Validate required fields
      if (!sellerId || !amount || !itemDescription) {
        return res.status(400).json({
          success: false,
          message: 'Seller ID, amount, and item description are required',
        });
      }

      // Calculate commission (2%)
      const commission = parseFloat((amount * 0.02).toFixed(2));
      const totalAmount = parseFloat((parseFloat(amount) + commission).toFixed(2));

      // Get buyer
      const buyer = await User.findById(buyerId);
      if (!buyer) {
        return res.status(404).json({
          success: false,
          message: 'Buyer not found',
        });
      }

      // Check buyer wallet balance
      if (buyer.wallet_balance < totalAmount) {
        return res.status(400).json({
          success: false,
          message: 'Insufficient wallet balance',
          data: {
            required: totalAmount,
            available: buyer.wallet_balance,
            shortfall: totalAmount - buyer.wallet_balance,
          },
        });
      }

      // Verify seller exists
      const seller = await User.findById(sellerId);
      if (!seller) {
        return res.status(404).json({
          success: false,
          message: 'Seller not found',
        });
      }

      // Verify rider if provided
      if (riderId) {
        const rider = await User.findById(riderId);
        if (!rider || rider.user_type !== 'rider') {
          return res.status(404).json({
            success: false,
            message: 'Rider not found or invalid',
          });
        }
      }

      await client.query('BEGIN');

      // Generate transaction reference
      const transactionRef = Transaction.generateTransactionRef();

      // Create transaction
      const transaction = await Transaction.create({
        transactionRef,
        buyerId,
        sellerId,
        riderId,
        amount,
        commission,
        totalAmount,
        transactionType: 'escrow',
        itemDescription,
        itemCategory,
        deliveryAddress,
        paymentMethod: 'wallet',
        notes,
      });

      // Create escrow account
      const escrow = await Escrow.create(transaction.id, totalAmount);

      // Deduct from buyer's wallet
      await client.query(
        'UPDATE users SET wallet_balance = wallet_balance - $1 WHERE id = $2',
        [totalAmount, buyerId]
      );

      await client.query('COMMIT');

      logger.info(`Escrow transaction created: ${transactionRef}`);

      res.status(201).json({
        success: true,
        message: 'Escrow transaction created successfully',
        data: {
          transaction: {
            id: transaction.id,
            transactionRef: transaction.transaction_ref,
            amount: transaction.amount,
            commission: transaction.commission,
            totalAmount: transaction.total_amount,
            status: transaction.status,
            itemDescription: transaction.item_description,
            createdAt: transaction.created_at,
          },
          escrow: {
            escrowRef: escrow.escrow_ref,
            amount: escrow.amount,
            status: escrow.status,
          },
        },
      });
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Create escrow transaction error:', error);
      next(error);
    } finally {
      client.release();
    }
  }

  // Get transaction by ID
  static async getTransaction(req, res, next) {
    try {
      const { transactionId } = req.params;
      const userId = req.user.userId;

      const transaction = await Transaction.findById(transactionId);

      if (!transaction) {
        return res.status(404).json({
          success: false,
          message: 'Transaction not found',
        });
      }

      // Check if user is part of the transaction
      const isParticipant =
        transaction.buyer_id === userId ||
        transaction.seller_id === userId ||
        transaction.rider_id === userId;

      if (!isParticipant) {
        return res.status(403).json({
          success: false,
          message: 'Access denied',
        });
      }

      // Get escrow details
      const escrow = await Escrow.findByTransactionId(transactionId);

      // Get status history
      const statusHistory = await Transaction.getStatusHistory(transactionId);

      res.status(200).json({
        success: true,
        data: {
          transaction,
          escrow,
          statusHistory,
        },
      });
    } catch (error) {
      logger.error('Get transaction error:', error);
      next(error);
    }
  }

  // Get user's transactions
  static async getUserTransactions(req, res, next) {
    try {
      const userId = req.user.userId;
      const { role } = req.query; // buyer, seller, rider

      const transactions = await Transaction.findByUserId(userId, role);

      res.status(200).json({
        success: true,
        data: {
          transactions,
          count: transactions.length,
        },
      });
    } catch (error) {
      logger.error('Get user transactions error:', error);
      next(error);
    }
  }

  // Confirm delivery (buyer)
  static async confirmDelivery(req, res, next) {
    const client = await db.pool.connect();

    try {
      const { transactionId } = req.params;
      const buyerId = req.user.userId;

      const transaction = await Transaction.findById(transactionId);

      if (!transaction) {
        return res.status(404).json({
          success: false,
          message: 'Transaction not found',
        });
      }

      // Verify buyer
      if (transaction.buyer_id !== buyerId) {
        return res.status(403).json({
          success: false,
          message: 'Only the buyer can confirm delivery',
        });
      }

      // Check transaction status
      if (transaction.status !== 'delivered') {
        return res.status(400).json({
          success: false,
          message: 'Transaction must be in delivered status',
        });
      }

      await client.query('BEGIN');

      // Update transaction status
      await Transaction.updateStatus(
        transactionId,
        'completed',
        buyerId,
        'Delivery confirmed by buyer'
      );

      // Release escrow
      const escrow = await Escrow.release(
        transactionId,
        'Delivery confirmed by buyer'
      );

      // Add funds to seller's wallet (minus commission)
      await client.query(
        'UPDATE users SET wallet_balance = wallet_balance + $1 WHERE id = $2',
        [transaction.amount, transaction.seller_id]
      );

      await client.query('COMMIT');

      logger.info(`Delivery confirmed for transaction: ${transaction.transaction_ref}`);

      res.status(200).json({
        success: true,
        message: 'Delivery confirmed and payment released to seller',
        data: {
          transaction: {
            status: 'completed',
          },
          escrow: {
            status: escrow.status,
            releasedAt: escrow.released_at,
          },
        },
      });
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Confirm delivery error:', error);
      next(error);
    } finally {
      client.release();
    }
  }

  // Reject delivery (buyer)
  static async rejectDelivery(req, res, next) {
    const client = await db.pool.connect();

    try {
      const { transactionId } = req.params;
      const { reason } = req.body;
      const buyerId = req.user.userId;

      const transaction = await Transaction.findById(transactionId);

      if (!transaction) {
        return res.status(404).json({
          success: false,
          message: 'Transaction not found',
        });
      }

      // Verify buyer
      if (transaction.buyer_id !== buyerId) {
        return res.status(403).json({
          success: false,
          message: 'Only the buyer can reject delivery',
        });
      }

      // Check transaction status
      if (transaction.status !== 'delivered') {
        return res.status(400).json({
          success: false,
          message: 'Transaction must be in delivered status',
        });
      }

      await client.query('BEGIN');

      // Update transaction status
      await Transaction.updateStatus(
        transactionId,
        'disputed',
        buyerId,
        reason || 'Delivery rejected by buyer'
      );

      await client.query('COMMIT');

      logger.info(`Delivery rejected for transaction: ${transaction.transaction_ref}`);

      res.status(200).json({
        success: true,
        message: 'Delivery rejected. Transaction moved to dispute.',
        data: {
          transaction: {
            status: 'disputed',
          },
        },
      });
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Reject delivery error:', error);
      next(error);
    } finally {
      client.release();
    }
  }

  // Update transaction status
  static async updateTransactionStatus(req, res, next) {
    try {
      const { transactionId } = req.params;
      const { status, reason } = req.body;
      const userId = req.user.userId;

      const transaction = await Transaction.findById(transactionId);

      if (!transaction) {
        return res.status(404).json({
          success: false,
          message: 'Transaction not found',
        });
      }

      // Check if user is part of the transaction
      const isParticipant =
        transaction.buyer_id === userId ||
        transaction.seller_id === userId ||
        transaction.rider_id === userId;

      if (!isParticipant) {
        return res.status(403).json({
          success: false,
          message: 'Access denied',
        });
      }

      const updatedTransaction = await Transaction.updateStatus(
        transactionId,
        status,
        userId,
        reason
      );

      res.status(200).json({
        success: true,
        message: 'Transaction status updated',
        data: {
          transaction: updatedTransaction,
        },
      });
    } catch (error) {
      logger.error('Update transaction status error:', error);
      next(error);
    }
  }
}

module.exports = EscrowController;
