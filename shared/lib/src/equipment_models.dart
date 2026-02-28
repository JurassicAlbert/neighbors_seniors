import 'constants.dart';
import 'models.dart';

class EquipmentModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final EquipmentCategory category;
  final EquipmentCondition condition;
  final EquipmentStatus status;
  final List<String> photoUrls;
  final double pricePerUnit;
  final PriceUnit priceUnit;
  final double? depositAmount;
  final String? location;
  final double? lat;
  final double? lng;
  final bool isRecurring;
  final String? availabilitySchedule;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? owner;

  const EquipmentModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    this.status = EquipmentStatus.available,
    this.photoUrls = const [],
    required this.pricePerUnit,
    this.priceUnit = PriceUnit.day,
    this.depositAmount,
    this.location,
    this.lat,
    this.lng,
    this.isRecurring = false,
    this.availabilitySchedule,
    required this.createdAt,
    required this.updatedAt,
    this.owner,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'category': category.name,
        'condition': condition.name,
        'status': status.name,
        'photoUrls': photoUrls,
        'pricePerUnit': pricePerUnit,
        'priceUnit': priceUnit.name,
        'depositAmount': depositAmount,
        'location': location,
        'lat': lat,
        'lng': lng,
        'isRecurring': isRecurring,
        'availabilitySchedule': availabilitySchedule,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (owner != null) 'owner': owner!.toJson(),
      };

  factory EquipmentModel.fromJson(Map<String, dynamic> json) =>
      EquipmentModel(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        category: EquipmentCategory.values
            .firstWhere((e) => e.name == json['category']),
        condition: EquipmentCondition.values
            .firstWhere((e) => e.name == json['condition']),
        status: EquipmentStatus.values
            .firstWhere((e) => e.name == json['status'], orElse: () => EquipmentStatus.available),
        photoUrls: (json['photoUrls'] as List<dynamic>?)
                ?.map((p) => p as String)
                .toList() ??
            [],
        pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
        priceUnit: PriceUnit.values
            .firstWhere((e) => e.name == json['priceUnit'], orElse: () => PriceUnit.day),
        depositAmount: (json['depositAmount'] as num?)?.toDouble(),
        location: json['location'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        isRecurring: json['isRecurring'] as bool? ?? false,
        availabilitySchedule: json['availabilitySchedule'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        owner: json['owner'] != null
            ? UserModel.fromJson(json['owner'] as Map<String, dynamic>)
            : null,
      );
}

class EquipmentReservation {
  final String id;
  final String equipmentId;
  final String borrowerId;
  final String ownerId;
  final EquipmentStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final double? depositAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EquipmentModel? equipment;
  final UserModel? borrower;

  const EquipmentReservation({
    required this.id,
    required this.equipmentId,
    required this.borrowerId,
    required this.ownerId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.depositAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.equipment,
    this.borrower,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'equipmentId': equipmentId,
        'borrowerId': borrowerId,
        'ownerId': ownerId,
        'status': status.name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'totalPrice': totalPrice,
        'depositAmount': depositAmount,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (equipment != null) 'equipment': equipment!.toJson(),
        if (borrower != null) 'borrower': borrower!.toJson(),
      };

  factory EquipmentReservation.fromJson(Map<String, dynamic> json) =>
      EquipmentReservation(
        id: json['id'] as String,
        equipmentId: json['equipmentId'] as String,
        borrowerId: json['borrowerId'] as String,
        ownerId: json['ownerId'] as String,
        status: EquipmentStatus.values
            .firstWhere((e) => e.name == json['status']),
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        totalPrice: (json['totalPrice'] as num).toDouble(),
        depositAmount: (json['depositAmount'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        equipment: json['equipment'] != null
            ? EquipmentModel.fromJson(json['equipment'] as Map<String, dynamic>)
            : null,
        borrower: json['borrower'] != null
            ? UserModel.fromJson(json['borrower'] as Map<String, dynamic>)
            : null,
      );
}
