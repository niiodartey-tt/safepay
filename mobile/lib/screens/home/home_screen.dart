import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/welcome_screen.dart';
import '../kyc/kyc_submission_screen.dart';
import '../escrow/create_transaction_screen.dart';
import '../escrow/transaction_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafePay Ghana'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await authProvider.checkAuthStatus();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                user.userType == 'buyer'
                                    ? Icons.shopping_bag_outlined
                                    : user.userType == 'seller'
                                        ? Icons.store_outlined
                                        : Icons.delivery_dining_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.userType.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Wallet Balance
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wallet Balance',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'GH₵ ${user.walletBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Top up feature coming soon!'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text('Top Up'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Send feature coming soon!'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.send, size: 20),
                                  label: const Text('Send'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Action Cards Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: _buildActionCards(context, user.userType, user.kycStatus),
                    ),
                    const SizedBox(height: 24),
                    
                    // Account Info
                    _buildInfoCard(
                      title: 'Account Information',
                      children: [
                        _buildInfoRow('Phone Number', user.phoneNumber),
                        if (user.email != null)
                          _buildInfoRow('Email', user.email!),
                        _buildInfoRow('Account Type', user.userType.toUpperCase()),
                        _buildInfoRow(
                          'KYC Status',
                          user.kycStatus.toUpperCase(),
                          valueColor: user.kycStatus == 'approved'
                              ? AppTheme.secondaryColor
                              : user.kycStatus == 'pending'
                                  ? AppTheme.warningColor
                                  : AppTheme.errorColor,
                        ),
                        _buildInfoRow(
                          'Verification Status',
                          user.isVerified ? 'VERIFIED' : 'NOT VERIFIED',
                          valueColor: user.isVerified
                              ? AppTheme.secondaryColor
                              : AppTheme.errorColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildActionCards(BuildContext context, String userType, String kycStatus) {
    List<Widget> cards = [];

    // New Purchase/Sale - Only for buyers and sellers
    if (userType == 'buyer') {
      cards.add(
        _buildActionCard(
          icon: Icons.add_shopping_cart,
          title: 'New Purchase',
          color: AppTheme.primaryColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateTransactionScreen(),
              ),
            );
          },
        ),
      );
    } else if (userType == 'seller') {
      cards.add(
        _buildActionCard(
          icon: Icons.point_of_sale,
          title: 'New Sale',
          color: AppTheme.primaryColor,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Seller interface coming soon!'),
              ),
            );
          },
        ),
      );
    } else if (userType == 'rider') {
      cards.add(
        _buildActionCard(
          icon: Icons.local_shipping,
          title: 'Available Orders',
          color: AppTheme.primaryColor,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rider interface coming soon!'),
              ),
            );
          },
        ),
      );
    }

    // Transactions - For all users
    cards.add(
      _buildActionCard(
        icon: Icons.history,
        title: 'Transactions',
        color: AppTheme.secondaryColor,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionListScreen(),
            ),
          );
        },
      ),
    );

    // KYC - For all users
    cards.add(
      _buildActionCard(
        icon: Icons.verified_user,
        title: kycStatus == 'approved' ? 'KYC Verified' : 'Complete KYC',
        color: kycStatus == 'approved' 
            ? AppTheme.secondaryColor 
            : AppTheme.warningColor,
        onTap: () {
          if (kycStatus != 'approved') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const KYCSubmissionScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your KYC is already verified!'),
                backgroundColor: AppTheme.secondaryColor,
              ),
            );
          }
        },
      ),
    );

    // My Profile - For all users
    cards.add(
      _buildActionCard(
        icon: Icons.person,
        title: 'My Profile',
        color: const Color(0xFF8B5CF6),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile screen coming soon!'),
            ),
          );
        },
      ),
    );

    return cards;
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
