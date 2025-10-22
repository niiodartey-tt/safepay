import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String message;
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;

  AuthResponseModel({
    required this.success,
    required this.message,
    this.user,
    this.accessToken,
    this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'],
      message: json['message'],
      user: json['data']?['user'] != null
          ? UserModel.fromJson(json['data']['user'])
          : null,
      accessToken: json['data']?['accessToken'],
      refreshToken: json['data']?['refreshToken'],
    );
  }
}
