import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/transaction_model.dart';
import 'storage_service.dart';

class EscrowService {
  static Future<Map<String, dynamic>> createTransaction({
    required String sellerId,
    required double amount,
    required String itemDescription,
    String? itemCategory,
    String? deliveryAddress,
    String? riderId,
    String? notes,
  }) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/escrow/transaction/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'sellerId': sellerId,
          'amount': amount,
          'itemDescription': itemDescription,
          'itemCategory': itemCategory,
          'deliveryAddress': deliveryAddress,
          'riderId': riderId,
          'notes': notes,
        }),
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTransaction(String transactionId) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/escrow/transaction/$transactionId'),
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

  static Future<List<TransactionModel>> getUserTransactions({String? role}) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) return [];

      String url = '${ApiConfig.baseUrl}/escrow/transactions';
      if (role != null) {
        url += '?role=$role';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List transactions = data['data']['transactions'];
        return transactions.map((t) => TransactionModel.fromJson(t)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> confirmDelivery(String transactionId) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/escrow/transaction/$transactionId/confirm-delivery'),
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

  static Future<Map<String, dynamic>> rejectDelivery(
    String transactionId,
    String reason,
  ) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/escrow/transaction/$transactionId/reject-delivery'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateTransactionStatus(
    String transactionId,
    String status, {
    String? reason,
  }) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/escrow/transaction/$transactionId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
          'reason': reason,
        }),
      ).timeout(ApiConfig.timeout);

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
