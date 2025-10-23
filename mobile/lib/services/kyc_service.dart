import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class KYCService {
  static Future<Map<String, dynamic>> submitKYC({
    required String idCardUrl,
    required String idCardNumber,
    required String profilePhotoUrl,
    String? address,
    String? dateOfBirth,
  }) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/kyc/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'idCardUrl': idCardUrl,
          'idCardNumber': idCardNumber,
          'profilePhotoUrl': profilePhotoUrl,
          'address': address,
          'dateOfBirth': dateOfBirth,
        }),
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getKYCDocuments() async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kyc/documents'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
