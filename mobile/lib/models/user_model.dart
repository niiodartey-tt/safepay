class UserModel {
  final String id;
  final String phoneNumber;
  final String? email;
  final String userType;
  final String fullName;
  final double walletBalance;
  final bool isVerified;
  final String kycStatus;
  final String? profilePhotoUrl;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.phoneNumber,
    this.email,
    required this.userType,
    required this.fullName,
    required this.walletBalance,
    required this.isVerified,
    required this.kycStatus,
    this.profilePhotoUrl,
    this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      userType: json['userType'],
      fullName: json['fullName'],
      walletBalance: double.parse(json['walletBalance'].toString()),
      isVerified: json['isVerified'] ?? false,
      kycStatus: json['kycStatus'] ?? 'pending',
      profilePhotoUrl: json['profilePhotoUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'email': email,
      'userType': userType,
      'fullName': fullName,
      'walletBalance': walletBalance,
      'isVerified': isVerified,
      'kycStatus': kycStatus,
      'profilePhotoUrl': profilePhotoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }
}
