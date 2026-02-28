import 'constants.dart';

class PaymentModel {
  final String id;
  final String? orderId;
  final String? reservationId;
  final String payerId;
  final String payeeId;
  final double amount;
  final double? depositAmount;
  final double? commissionAmount;
  final PaymentStatus status;
  final String? externalPaymentId;
  final String? provider;
  final String? disputeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentModel({
    required this.id,
    this.orderId,
    this.reservationId,
    required this.payerId,
    required this.payeeId,
    required this.amount,
    this.depositAmount,
    this.commissionAmount,
    required this.status,
    this.externalPaymentId,
    this.provider,
    this.disputeId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'reservationId': reservationId,
        'payerId': payerId,
        'payeeId': payeeId,
        'amount': amount,
        'depositAmount': depositAmount,
        'commissionAmount': commissionAmount,
        'status': status.name,
        'externalPaymentId': externalPaymentId,
        'provider': provider,
        'disputeId': disputeId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as String,
        orderId: json['orderId'] as String?,
        reservationId: json['reservationId'] as String?,
        payerId: json['payerId'] as String,
        payeeId: json['payeeId'] as String,
        amount: (json['amount'] as num).toDouble(),
        depositAmount: (json['depositAmount'] as num?)?.toDouble(),
        commissionAmount: (json['commissionAmount'] as num?)?.toDouble(),
        status: PaymentStatus.values
            .firstWhere((e) => e.name == json['status']),
        externalPaymentId: json['externalPaymentId'] as String?,
        provider: json['provider'] as String?,
        disputeId: json['disputeId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class DisputeModel {
  final String id;
  final DisputeType type;
  final String? orderId;
  final String? reservationId;
  final String? paymentId;
  final String reporterId;
  final String? respondentId;
  final String title;
  final String description;
  final DisputeStatus status;
  final String? adminNotes;
  final String? resolution;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DisputeModel({
    required this.id,
    required this.type,
    this.orderId,
    this.reservationId,
    this.paymentId,
    required this.reporterId,
    this.respondentId,
    required this.title,
    required this.description,
    required this.status,
    this.adminNotes,
    this.resolution,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'orderId': orderId,
        'reservationId': reservationId,
        'paymentId': paymentId,
        'reporterId': reporterId,
        'respondentId': respondentId,
        'title': title,
        'description': description,
        'status': status.name,
        'adminNotes': adminNotes,
        'resolution': resolution,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DisputeModel.fromJson(Map<String, dynamic> json) => DisputeModel(
        id: json['id'] as String,
        type: DisputeType.values.firstWhere((e) => e.name == json['type']),
        orderId: json['orderId'] as String?,
        reservationId: json['reservationId'] as String?,
        paymentId: json['paymentId'] as String?,
        reporterId: json['reporterId'] as String,
        respondentId: json['respondentId'] as String?,
        title: json['title'] as String,
        description: json['description'] as String,
        status: DisputeStatus.values
            .firstWhere((e) => e.name == json['status']),
        adminNotes: json['adminNotes'] as String?,
        resolution: json['resolution'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
