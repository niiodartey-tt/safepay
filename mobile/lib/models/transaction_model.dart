class TransactionModel {
  final String id;
  final String transactionRef;
  final String buyerId;
  final String sellerId;
  final String? riderId;
  final double amount;
  final double commission;
  final double totalAmount;
  final String transactionType;
  final String status;
  final String itemDescription;
  final String? itemCategory;
  final String? deliveryAddress;
  final String? buyerName;
  final String? sellerName;
  final String? riderName;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.transactionRef,
    required this.buyerId,
    required this.sellerId,
    this.riderId,
    required this.amount,
    required this.commission,
    required this.totalAmount,
    required this.transactionType,
    required this.status,
    required this.itemDescription,
    this.itemCategory,
    this.deliveryAddress,
    this.buyerName,
    this.sellerName,
    this.riderName,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      transactionRef: json['transaction_ref'],
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],
      riderId: json['rider_id'],
      amount: double.parse(json['amount'].toString()),
      commission: double.parse(json['commission'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      transactionType: json['transaction_type'],
      status: json['status'],
      itemDescription: json['item_description'],
      itemCategory: json['item_category'],
      deliveryAddress: json['delivery_address'],
      buyerName: json['buyer_name'],
      sellerName: json['seller_name'],
      riderName: json['rider_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String getStatusDisplay() {
    switch (status) {
      case 'pending':
        return 'Pending Payment';
      case 'paid':
        return 'Payment Held in Escrow';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered - Awaiting Confirmation';
      case 'completed':
        return 'Completed';
      case 'disputed':
        return 'Disputed';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }
}

class EscrowModel {
  final String escrowRef;
  final double amount;
  final String status;
  final DateTime heldAt;
  final DateTime? releasedAt;
  final DateTime? refundedAt;

  EscrowModel({
    required this.escrowRef,
    required this.amount,
    required this.status,
    required this.heldAt,
    this.releasedAt,
    this.refundedAt,
  });

  factory EscrowModel.fromJson(Map<String, dynamic> json) {
    return EscrowModel(
      escrowRef: json['escrow_ref'],
      amount: double.parse(json['amount'].toString()),
      status: json['status'],
      heldAt: DateTime.parse(json['held_at']),
      releasedAt: json['released_at'] != null
          ? DateTime.parse(json['released_at'])
          : null,
      refundedAt: json['refunded_at'] != null
          ? DateTime.parse(json['refunded_at'])
          : null,
    );
  }
}
