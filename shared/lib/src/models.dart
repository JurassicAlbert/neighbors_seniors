import 'constants.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final List<UserCapability> capabilities;
  final String? avatarUrl;
  final String? address;
  final double? lat;
  final double? lng;
  final VerificationStatus verificationStatus;
  final String? idDocumentUrl;
  final String? selfieUrl;
  final int points;
  final int level;
  final List<String> badgeIds;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.capabilities = const [UserCapability.requester],
    this.avatarUrl,
    this.address,
    this.lat,
    this.lng,
    this.verificationStatus = VerificationStatus.unverified,
    this.idDocumentUrl,
    this.selfieUrl,
    this.points = 0,
    this.level = 1,
    this.badgeIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'role': role.name,
        'capabilities': capabilities.map((c) => c.name).toList(),
        'avatarUrl': avatarUrl,
        'address': address,
        'lat': lat,
        'lng': lng,
        'verificationStatus': verificationStatus.name,
        'idDocumentUrl': idDocumentUrl,
        'selfieUrl': selfieUrl,
        'points': points,
        'level': level,
        'badgeIds': badgeIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String? ?? '',
        role: UserRole.values.firstWhere((e) => e.name == json['role']),
        capabilities: (json['capabilities'] as List<dynamic>?)
                ?.map((c) => UserCapability.values.firstWhere((e) => e.name == c))
                .toList() ??
            [UserCapability.requester],
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
        points: json['points'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        badgeIds: (json['badgeIds'] as List<dynamic>?)
                ?.map((b) => b as String)
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  UserModel copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? address,
    double? lat,
    double? lng,
    List<UserCapability>? capabilities,
    VerificationStatus? verificationStatus,
    int? points,
    int? level,
    List<String>? badgeIds,
  }) =>
      UserModel(
        id: id,
        email: email,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        role: role,
        capabilities: capabilities ?? this.capabilities,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        address: address ?? this.address,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        idDocumentUrl: idDocumentUrl,
        selfieUrl: selfieUrl,
        points: points ?? this.points,
        level: level ?? this.level,
        badgeIds: badgeIds ?? this.badgeIds,
        createdAt: createdAt,
      );

  bool hasCapability(UserCapability cap) => capabilities.contains(cap);
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
  final AccessType? accessType;
  final String? accessCode;
  final DateTime? scheduledAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final DateTime createdAt;
  final DateTime updatedAt;
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
    this.accessType,
    this.accessCode,
    this.scheduledAt,
    this.checkedInAt,
    this.checkedOutAt,
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
        'accessType': accessType?.name,
        'accessCode': accessCode,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'checkedInAt': checkedInAt?.toIso8601String(),
        'checkedOutAt': checkedOutAt?.toIso8601String(),
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
        accessType: json['accessType'] != null
            ? AccessType.values.firstWhere((e) => e.name == json['accessType'])
            : null,
        accessCode: json['accessCode'] as String?,
        scheduledAt: json['scheduledAt'] != null
            ? DateTime.parse(json['scheduledAt'] as String)
            : null,
        checkedInAt: json['checkedInAt'] != null
            ? DateTime.parse(json['checkedInAt'] as String)
            : null,
        checkedOutAt: json['checkedOutAt'] != null
            ? DateTime.parse(json['checkedOutAt'] as String)
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
  final Map<String, int> categoryRatings;
  final DateTime createdAt;
  final UserModel? reviewer;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    this.categoryRatings = const {},
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
        'categoryRatings': categoryRatings,
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
        categoryRatings: (json['categoryRatings'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
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
  final NotificationType type;
  final bool read;
  final String? orderId;
  final String? equipmentId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.read = false,
    this.orderId,
    this.equipmentId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'read': read,
        'orderId': orderId,
        'equipmentId': equipmentId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.values
            .firstWhere((e) => e.name == json['type'], orElse: () => NotificationType.newMessage),
        read: json['read'] as bool? ?? false,
        orderId: json['orderId'] as String?,
        equipmentId: json['equipmentId'] as String?,
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
  final int totalEquipment;
  final int activeReservations;
  final int openDisputes;
  final int totalFriendships;

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
    this.totalEquipment = 0,
    this.activeReservations = 0,
    this.openDisputes = 0,
    this.totalFriendships = 0,
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
        'totalEquipment': totalEquipment,
        'activeReservations': activeReservations,
        'openDisputes': openDisputes,
        'totalFriendships': totalFriendships,
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
        totalEquipment: json['totalEquipment'] as int? ?? 0,
        activeReservations: json['activeReservations'] as int? ?? 0,
        openDisputes: json['openDisputes'] as int? ?? 0,
        totalFriendships: json['totalFriendships'] as int? ?? 0,
      );
}
