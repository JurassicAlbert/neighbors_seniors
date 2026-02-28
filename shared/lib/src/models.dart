import 'constants.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final String? address;
  final double? lat;
  final double? lng;
  final VerificationStatus verificationStatus;
  final String? idDocumentUrl;
  final String? selfieUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.address,
    this.lat,
    this.lng,
    this.verificationStatus = VerificationStatus.unverified,
    this.idDocumentUrl,
    this.selfieUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'role': role.name,
        'avatarUrl': avatarUrl,
        'address': address,
        'lat': lat,
        'lng': lng,
        'verificationStatus': verificationStatus.name,
        'idDocumentUrl': idDocumentUrl,
        'selfieUrl': selfieUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String? ?? '',
        role: UserRole.values.firstWhere((e) => e.name == json['role']),
        avatarUrl: json['avatarUrl'] as String?,
        address: json['address'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        verificationStatus: json['verificationStatus'] != null
            ? VerificationStatus.values
                .firstWhere((e) => e.name == json['verificationStatus'])
            : VerificationStatus.unverified,
        idDocumentUrl: json['idDocumentUrl'] as String?,
        selfieUrl: json['selfieUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  UserModel copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? address,
    double? lat,
    double? lng,
    VerificationStatus? verificationStatus,
  }) =>
      UserModel(
        id: id,
        email: email,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        role: role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        address: address ?? this.address,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        idDocumentUrl: idDocumentUrl,
        selfieUrl: selfieUrl,
        createdAt: createdAt,
      );
}

class OrderModel {
  final String id;
  final OrderType type;
  final String title;
  final String description;
  final OrderStatus status;
  final String requesterId;
  final String? workerId;
  final String? seniorId;
  final double? price;
  final double? commission;
  final double? deposit;
  final String address;
  final double? lat;
  final double? lng;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated fields
  final UserModel? requester;
  final UserModel? worker;

  const OrderModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.requesterId,
    this.workerId,
    this.seniorId,
    this.price,
    this.commission,
    this.deposit,
    required this.address,
    this.lat,
    this.lng,
    this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    this.requester,
    this.worker,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'status': status.name,
        'requesterId': requesterId,
        'workerId': workerId,
        'seniorId': seniorId,
        'price': price,
        'commission': commission,
        'deposit': deposit,
        'address': address,
        'lat': lat,
        'lng': lng,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (requester != null) 'requester': requester!.toJson(),
        if (worker != null) 'worker': worker!.toJson(),
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        type: OrderType.values.firstWhere((e) => e.name == json['type']),
        title: json['title'] as String,
        description: json['description'] as String,
        status: OrderStatus.values.firstWhere((e) => e.name == json['status']),
        requesterId: json['requesterId'] as String,
        workerId: json['workerId'] as String?,
        seniorId: json['seniorId'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        commission: (json['commission'] as num?)?.toDouble(),
        deposit: (json['deposit'] as num?)?.toDouble(),
        address: json['address'] as String,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        scheduledAt: json['scheduledAt'] != null
            ? DateTime.parse(json['scheduledAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        requester: json['requester'] != null
            ? UserModel.fromJson(json['requester'] as Map<String, dynamic>)
            : null,
        worker: json['worker'] != null
            ? UserModel.fromJson(json['worker'] as Map<String, dynamic>)
            : null,
      );
}

class ReviewModel {
  final String id;
  final String orderId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final UserModel? reviewer;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewer,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'reviewerId': reviewerId,
        'revieweeId': revieweeId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        if (reviewer != null) 'reviewer': reviewer!.toJson(),
      };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        reviewerId: json['reviewerId'] as String,
        revieweeId: json['revieweeId'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        reviewer: json['reviewer'] != null
            ? UserModel.fromJson(json['reviewer'] as Map<String, dynamic>)
            : null,
      );
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final bool read;
  final String? orderId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.read = false,
    this.orderId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'read': read,
        'orderId': orderId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        read: json['read'] as bool? ?? false,
        orderId: json['orderId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AuthResponse {
  final String token;
  final UserModel user;

  const AuthResponse({required this.token, required this.user});

  Map<String, dynamic> toJson() => {
        'token': token,
        'user': user.toJson(),
      };

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class StatsModel {
  final int totalUsers;
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final double totalRevenue;
  final double totalCommission;
  final int verifiedWorkers;
  final int pendingVerifications;
  final Map<String, int> ordersByType;

  const StatsModel({
    required this.totalUsers,
    required this.totalOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.totalRevenue,
    required this.totalCommission,
    required this.verifiedWorkers,
    required this.pendingVerifications,
    required this.ordersByType,
  });

  Map<String, dynamic> toJson() => {
        'totalUsers': totalUsers,
        'totalOrders': totalOrders,
        'activeOrders': activeOrders,
        'completedOrders': completedOrders,
        'totalRevenue': totalRevenue,
        'totalCommission': totalCommission,
        'verifiedWorkers': verifiedWorkers,
        'pendingVerifications': pendingVerifications,
        'ordersByType': ordersByType,
      };

  factory StatsModel.fromJson(Map<String, dynamic> json) => StatsModel(
        totalUsers: json['totalUsers'] as int,
        totalOrders: json['totalOrders'] as int,
        activeOrders: json['activeOrders'] as int,
        completedOrders: json['completedOrders'] as int,
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        totalCommission: (json['totalCommission'] as num).toDouble(),
        verifiedWorkers: json['verifiedWorkers'] as int,
        pendingVerifications: json['pendingVerifications'] as int,
        ordersByType: Map<String, int>.from(json['ordersByType'] as Map),
      );
}
