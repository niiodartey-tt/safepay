import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/escrow_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _transactionData;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    setState(() => _isLoading = true);
    
    final result = await EscrowService.getTransaction(widget.transactionId);
    
    setState(() {
      if (result['success']) {
        _transactionData = result['data'];
      }
      _isLoading = false;
    });
  }

  Future<void> _confirmDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text(
          'Have you received the item in good condition? This will release the payment to the seller.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await EscrowService.confirmDelivery(widget.transactionId);
      if (result['success']) {
        _showSuccess('Delivery confirmed! Payment released to seller.');
        _loadTransaction();
      } else {
        _showError(result['message'] ?? 'Failed to confirm delivery');
      }
    }
  }

  Future<void> _rejectDelivery() async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you rejecting this delivery?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      final result = await EscrowService.rejectDelivery(
        widget.transactionId,
        reasonController.text.trim(),
      );
      
      if (result['success']) {
        _showSuccess('Delivery rejected. Transaction moved to dispute.');
        _loadTransaction();
      } else {
        _showError(result['message'] ?? 'Failed to reject delivery');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'paid':
      case 'in_transit':
        return AppTheme.primaryColor;
      case 'delivered':
        return Colors.orange;
      case 'completed':
        return AppTheme.secondaryColor;
      case 'disputed':
      case 'cancelled':
        return AppTheme.errorColor;
      case 'refunded':
        return Colors.grey;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_transactionData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
        body: const Center(
          child: Text('Transaction not found'),
        ),
      );
    }

    final transaction = TransactionModel.fromJson(_transactionData!['transaction']);
    final escrow = _transactionData!['escrow'] != null
        ? EscrowModel.fromJson(_transactionData!['escrow'])
        : null;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    final isBuyer = transaction.buyerId == userId;
    final isSeller = transaction.sellerId == userId;
    final canConfirmDelivery = isBuyer && transaction.status == 'delivered';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getStatusColor(transaction.status),
                    width: 2,
                  ),
                ),
                child: Text(
                  transaction.getStatusDisplay(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(transaction.status),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GH₵ ${transaction.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transaction.transactionRef,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Item Details
            _buildSectionTitle('Item Details'),
            _buildInfoCard([
              _buildInfoRow('Description', transaction.itemDescription),
              if (transaction.itemCategory != null)
                _buildInfoRow('Category', transaction.itemCategory!),
              if (transaction.deliveryAddress != null)
                _buildInfoRow('Delivery Address', transaction.deliveryAddress!),
            ]),
            const SizedBox(height: 16),
            
            // Transaction Parties
            _buildSectionTitle('Transaction Parties'),
            _buildInfoCard([
              _buildInfoRow(
                'Buyer',
                transaction.buyerName ?? 'Unknown',
                highlight: isBuyer,
              ),
              _buildInfoRow(
                'Seller',
                transaction.sellerName ?? 'Unknown',
                highlight: isSeller,
              ),
              if (transaction.riderName != null)
                _buildInfoRow('Rider', transaction.riderName!),
            ]),
            const SizedBox(height: 16),
            
            // Payment Breakdown
            _buildSectionTitle('Payment Breakdown'),
            _buildInfoCard([
              _buildInfoRow(
                'Item Amount',
                'GH₵ ${transaction.amount.toStringAsFixed(2)}',
              ),
              _buildInfoRow(
                'Service Fee (2%)',
                'GH₵ ${transaction.commission.toStringAsFixed(2)}',
              ),
              const Divider(height: 20),
              _buildInfoRow(
                'Total Amount',
                'GH₵ ${transaction.totalAmount.toStringAsFixed(2)}',
                isBold: true,
              ),
            ]),
            const SizedBox(height: 16),
            
            // Escrow Details
            if (escrow != null) ...[
              _buildSectionTitle('Escrow Details'),
              _buildInfoCard([
                _buildInfoRow('Escrow Reference', escrow.escrowRef),
                _buildInfoRow('Escrow Status', escrow.status.toUpperCase()),
                _buildInfoRow(
                  'Held Amount',
                  'GH₵ ${escrow.amount.toStringAsFixed(2)}',
                ),
                _buildInfoRow('Held Since', _formatDateTime(escrow.heldAt)),
                if (escrow.releasedAt != null)
                  _buildInfoRow('Released At', _formatDateTime(escrow.releasedAt!)),
                if (escrow.refundedAt != null)
                  _buildInfoRow('Refunded At', _formatDateTime(escrow.refundedAt!)),
              ]),
              const SizedBox(height: 16),
            ],
            
            // Transaction Info
            _buildSectionTitle('Transaction Information'),
            _buildInfoCard([
              _buildInfoRow('Transaction Type', transaction.transactionType.toUpperCase()),
              _buildInfoRow('Created At', _formatDateTime(transaction.createdAt)),
            ]),
            const SizedBox(height: 24),
            
            // Action Buttons
            if (canConfirmDelivery) ...[
              const Text(
                'Delivery Confirmation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warningColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please confirm if you have received the item in good condition',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _rejectDelivery,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _confirmDelivery,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm Delivery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              highlight ? '$value (You)' : value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: highlight ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute';
  }
}
