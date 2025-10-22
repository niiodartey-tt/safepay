import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
  
  static const Duration timeout = Duration(seconds: 30);
  
  // API Endpoints
  static const String health = '/health';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
}
