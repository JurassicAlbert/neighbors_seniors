import 'constants.dart';
import 'models.dart';

class FriendshipModel {
  final String id;
  final String userId;
  final String friendId;
  final FriendshipStatus status;
  final String? tag;
  final DateTime createdAt;
  final UserModel? friend;

  const FriendshipModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    this.tag,
    required this.createdAt,
    this.friend,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'friendId': friendId,
        'status': status.name,
        'tag': tag,
        'createdAt': createdAt.toIso8601String(),
        if (friend != null) 'friend': friend!.toJson(),
      };

  factory FriendshipModel.fromJson(Map<String, dynamic> json) =>
      FriendshipModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        friendId: json['friendId'] as String,
        status: FriendshipStatus.values
            .firstWhere((e) => e.name == json['status']),
        tag: json['tag'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        friend: json['friend'] != null
            ? UserModel.fromJson(json['friend'] as Map<String, dynamic>)
            : null,
      );
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int requiredPoints;
  final String? category;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredPoints,
    this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'requiredPoints': requiredPoints,
        'category': category,
      };

  factory BadgeModel.fromJson(Map<String, dynamic> json) => BadgeModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        requiredPoints: json['requiredPoints'] as int,
        category: json['category'] as String?,
      );
}

class AccessCodeModel {
  final String id;
  final String orderId;
  final String granterId;
  final String? recipientId;
  final String code;
  final AccessType accessType;
  final String? instructions;
  final DateTime expiresAt;
  final bool used;
  final DateTime createdAt;

  const AccessCodeModel({
    required this.id,
    required this.orderId,
    required this.granterId,
    this.recipientId,
    required this.code,
    required this.accessType,
    this.instructions,
    required this.expiresAt,
    this.used = false,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'granterId': granterId,
        'recipientId': recipientId,
        'code': code,
        'accessType': accessType.name,
        'instructions': instructions,
        'expiresAt': expiresAt.toIso8601String(),
        'used': used,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AccessCodeModel.fromJson(Map<String, dynamic> json) =>
      AccessCodeModel(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        granterId: json['granterId'] as String,
        recipientId: json['recipientId'] as String?,
        code: json['code'] as String,
        accessType: AccessType.values
            .firstWhere((e) => e.name == json['accessType']),
        instructions: json['instructions'] as String?,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        used: json['used'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class CheckInLog {
  final String id;
  final String orderId;
  final String userId;
  final bool isCheckIn;
  final double? lat;
  final double? lng;
  final DateTime timestamp;

  const CheckInLog({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.isCheckIn,
    this.lat,
    this.lng,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'userId': userId,
        'isCheckIn': isCheckIn,
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CheckInLog.fromJson(Map<String, dynamic> json) => CheckInLog(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        userId: json['userId'] as String,
        isCheckIn: json['isCheckIn'] as bool,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
