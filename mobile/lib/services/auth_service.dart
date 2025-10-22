import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  // Send OTP to phone number
  static Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber}),
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'expiresAt': data['data']['expiresAt'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Register new user
  static Future<AuthResponseModel> register({
    required String phoneNumber,
    required String fullName,
    required String userType,
    required String otpCode,
    String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'fullName': fullName,
          'userType': userType,
          'otpCode': otpCode,
          'email': email,
        }),
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);
      final authResponse = AuthResponseModel.fromJson(data);

      if (authResponse.success && authResponse.accessToken != null) {
        // Save tokens and user data
        await StorageService.saveAccessToken(authResponse.accessToken!);
        await StorageService.saveRefreshToken(authResponse.refreshToken!);
        await StorageService.saveUserData(json.encode(authResponse.user!.toJson()));
      }

      return authResponse;
    } catch (e) {
      return AuthResponseModel(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Login existing user
  static Future<AuthResponseModel> login({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'otpCode': otpCode,
        }),
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);
      final authResponse = AuthResponseModel.fromJson(data);

      if (authResponse.success && authResponse.accessToken != null) {
        // Save tokens and user data
        await StorageService.saveAccessToken(authResponse.accessToken!);
        await StorageService.saveRefreshToken(authResponse.refreshToken!);
        await StorageService.saveUserData(json.encode(authResponse.user!.toJson()));
      }

      return authResponse;
    } catch (e) {
      return AuthResponseModel(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get current user profile
  static Future<UserModel?> getProfile() async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data['data']['user']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Logout
  static Future<void> logout() async {
    await StorageService.clearAll();
  }

  // Get saved user data
  static Future<UserModel?> getSavedUser() async {
    try {
      final userData = await StorageService.getUserData();
      if (userData == null) return null;
      return UserModel.fromJson(json.decode(userData));
    } catch (e) {
      return null;
    }
  }
}
