// Add this to the _confirmDelivery method after successful confirmation:

if (confirmed == true) {
  final result = await EscrowService.confirmDelivery(widget.transactionId);
  if (result['success']) {
    // Refresh user data to update wallet balance
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUserData();
    
    _showSuccess('Delivery confirmed! Payment released to seller.');
    _loadTransaction();
  } else {
    _showError(result['message'] ?? 'Failed to confirm delivery');
  }
}
