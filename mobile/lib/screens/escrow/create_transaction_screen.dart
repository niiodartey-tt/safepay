// mobile/lib/screens/escrow/create_transaction_screen.dart
// ENHANCED VERSION WITH GUARANTEED BALANCE REFRESH AFTER TRANSACTION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/escrow_service.dart';

class CreateTransactionScreen extends StatefulWidget {
  const CreateTransactionScreen({Key? key}) : super(key: key);

  @override
  State<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sellerIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _itemDescriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = false;
  double _commission = 0.0;
  double _totalAmount = 0.0;

  @override
  void dispose() {
    _sellerIdController.dispose();
    _amountController.dispose();
    _itemDescriptionController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _commission = amount * 0.02;
      _totalAmount = amount + _commission;
    });
  }

  // ENHANCED: Transaction creation with guaranteed balance refresh
  Future<void> _createTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      _showError('Please login first');
      return;
    }

    if (user.walletBalance < _totalAmount) {
      _showError(
        'Insufficient balance. You need GH₵ ${_totalAmount.toStringAsFixed(2)} but have GH₵ ${user.walletBalance.toStringAsFixed(2)}',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create the transaction
      final result = await EscrowService.createTransaction(
        sellerId: _sellerIdController.text.trim(),
        amount: double.parse(_amountController.text),
        itemDescription: _itemDescriptionController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (result['success']) {
        // Show immediate feedback
        _showSuccess('Transaction created! Updating balance...');
        
        // Calculate new balance
        final newBalance = user.walletBalance - _totalAmount;
        
        // Update balance immediately (optimistic update)
        await authProvider.updateWalletBalance(newBalance);
        
        // Wait a moment for backend to process
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force refresh to get actual balance from server
        await authProvider.refreshUserData();
        
        // Navigate back with success
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Transaction created successfully! Balance updated.'),
              backgroundColor: AppTheme.secondaryColor,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        _showError(result['message'] ?? 'Failed to create transaction');
      }
    } catch (e) {
      _showError('Error creating transaction: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.secondaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCostRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          'GH₵ $amount',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Balance Card with refresh indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        // NEW: Show refresh indicator when updating
                        if (authProvider.isRefreshing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GH₵ ${user?.walletBalance.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Seller ID Field
              TextFormField(
                controller: _sellerIdController,
                decoration: const InputDecoration(
                  labelText: 'Seller ID',
                  hintText: 'Enter seller\'s SafePay ID',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter seller ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.money),
                  prefixText: 'GH₵ ',
                ),
                onChanged: (value) => _calculateTotal(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Item Description
              TextFormField(
                controller: _itemDescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Item Description',
                  hintText: 'Describe the item being purchased',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Delivery Address
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  hintText: 'Enter delivery location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Notes (Optional)
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any additional information',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Cost Breakdown
              if (_totalAmount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildCostRow(
                        'Item Amount',
                        _amountController.text.isEmpty ? '0.00' : _amountController.text,
                      ),
                      const SizedBox(height: 8),
                      _buildCostRow(
                        'Platform Fee (2%)',
                        _commission.toStringAsFixed(2),
                      ),
                      const Divider(height: 24),
                      _buildCostRow(
                        'Total Amount',
                        _totalAmount.toStringAsFixed(2),
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: AppTheme.secondaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Funds held in escrow',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Money will be released to seller only after you confirm delivery',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondaryColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Create Transaction Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createTransaction,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Escrow Transaction',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}