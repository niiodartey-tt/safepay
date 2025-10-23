// mobile/lib/providers/auth_provider.dart
// ENHANCED VERSION WITH AUTOMATIC BALANCE REFRESH

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isRefreshing = false; // NEW: Track if balance is being refreshed
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing; // NEW: Expose refresh state
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await StorageService.isLoggedIn();
      if (isLoggedIn) {
        // Try to get fresh user data from API
        final freshUser = await AuthService.getProfile();
        if (freshUser != null) {
          _user = freshUser;
          _isAuthenticated = true;
          // Update stored user data
          await StorageService.saveUserData(
            '${_user!.toJson()}'.replaceAll('Instance of \'', '').replaceAll('\'', ''),
          );
        } else {
          // Fallback to stored data
          _user = await AuthService.getSavedUser();
          _isAuthenticated = _user != null;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to check auth status';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ENHANCED: Refresh user data from server with better state management
  Future<void> refreshUserData({bool silent = false}) async {
    if (!silent) {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      final freshUser = await AuthService.getProfile();
      if (freshUser != null) {
        _user = freshUser;
        // Update stored user data
        await StorageService.saveUserData(
          '${_user!.toJson()}'.replaceAll('Instance of \'', '').replaceAll('\'', ''),
        );
        debugPrint('✅ Balance refreshed: GH₵ ${freshUser.walletBalance}');
      }
    } catch (e) {
      debugPrint('❌ Failed to refresh user data: $e');
      _errorMessage = 'Failed to refresh balance';
    } finally {
      if (!silent) {
        _isRefreshing = false;
      }
      notifyListeners();
    }
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.sendOTP(phoneNumber);

    _isLoading = false;
    notifyListeners();

    return result;
  }

  // Register
  Future<bool> register({
    required String phoneNumber,
    required String fullName,
    required String userType,
    required String otpCode,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await AuthService.register(
      phoneNumber: phoneNumber,
      fullName: fullName,
      userType: userType,
      otpCode: otpCode,
      email: email,
    );

    if (response.success && response.user != null) {
      _user = response.user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String phoneNumber,
    required String otpCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await AuthService.login(
      phoneNumber: phoneNumber,
      otpCode: otpCode,
    );

    if (response.success && response.user != null) {
      _user = response.user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ENHANCED: Update wallet balance with immediate server refresh
  Future<void> updateWalletBalance(double newBalance) async {
    if (_user != null) {
      // Optimistic update - update UI immediately
      _user = UserModel(
        id: _user!.id,
        phoneNumber: _user!.phoneNumber,
        email: _user!.email,
        userType: _user!.userType,
        fullName: _user!.fullName,
        walletBalance: newBalance,
        isVerified: _user!.isVerified,
        kycStatus: _user!.kycStatus,
        profilePhotoUrl: _user!.profilePhotoUrl,
        createdAt: _user!.createdAt,
        lastLoginAt: _user!.lastLoginAt,
      );
      notifyListeners();
      
      debugPrint('⚡ Optimistic balance update: GH₵ $newBalance');
      
      // Refresh from server to get accurate balance (silent refresh)
      await refreshUserData(silent: true);
    }
  }

  // NEW: Force refresh (for pull-to-refresh gestures)
  Future<void> forceRefresh() async {
    await refreshUserData(silent: false);
  }
}