class KYCDocumentModel {
  final String id;
  final String documentType;
  final String documentUrl;
  final String? documentNumber;
  final bool verified;
  final String? rejectionReason;
  final DateTime createdAt;

  KYCDocumentModel({
    required this.id,
    required this.documentType,
    required this.documentUrl,
    this.documentNumber,
    required this.verified,
    this.rejectionReason,
    required this.createdAt,
  });

  factory KYCDocumentModel.fromJson(Map<String, dynamic> json) {
    return KYCDocumentModel(
      id: json['id'],
      documentType: json['document_type'],
      documentUrl: json['document_url'],
      documentNumber: json['document_number'],
      verified: json['verified'] ?? false,
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
