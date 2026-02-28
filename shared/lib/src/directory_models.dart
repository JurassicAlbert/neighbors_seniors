import 'constants.dart';
import 'models.dart';

class ServiceOffer {
  final String id;
  final String providerId;
  final String title;
  final String description;
  final OrderType serviceType;
  final double? priceFrom;
  final double? priceTo;
  final String? location;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final List<String> skills;
  final String? availabilitySchedule;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? provider;
  final double? averageRating;
  final int? completedOrders;

  const ServiceOffer({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.serviceType,
    this.priceFrom,
    this.priceTo,
    this.location,
    this.lat,
    this.lng,
    this.radiusKm,
    this.skills = const [],
    this.availabilitySchedule,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.provider,
    this.averageRating,
    this.completedOrders,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'providerId': providerId,
        'title': title,
        'description': description,
        'serviceType': serviceType.name,
        'priceFrom': priceFrom,
        'priceTo': priceTo,
        'location': location,
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        'skills': skills,
        'availabilitySchedule': availabilitySchedule,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (provider != null) 'provider': provider!.toJson(),
        'averageRating': averageRating,
        'completedOrders': completedOrders,
      };

  factory ServiceOffer.fromJson(Map<String, dynamic> json) => ServiceOffer(
        id: json['id'] as String,
        providerId: json['providerId'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        serviceType: OrderType.values
            .firstWhere((e) => e.name == json['serviceType']),
        priceFrom: (json['priceFrom'] as num?)?.toDouble(),
        priceTo: (json['priceTo'] as num?)?.toDouble(),
        location: json['location'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        radiusKm: (json['radiusKm'] as num?)?.toDouble(),
        skills: (json['skills'] as List<dynamic>?)
                ?.map((s) => s as String)
                .toList() ??
            [],
        availabilitySchedule: json['availabilitySchedule'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        provider: json['provider'] != null
            ? UserModel.fromJson(json['provider'] as Map<String, dynamic>)
            : null,
        averageRating: (json['averageRating'] as num?)?.toDouble(),
        completedOrders: json['completedOrders'] as int?,
      );
}
