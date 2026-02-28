class AppConstants {
  static const String appName = 'Sąsiedzi & Seniorzy';
  static const String appNameEn = 'Neighbors & Seniors';
  static const String apiVersion = 'v2';
  static const double platformCommissionRate = 0.10;
  static const int maxRating = 5;
  static const int minPasswordLength = 8;
  static const int accessCodeLength = 6;
  static const Duration accessCodeExpiry = Duration(hours: 24);
  static const int pointsPerCompletion = 10;
  static const int pointsPerReview = 5;
  static const int pointsPerVolunteer = 20;
  static const int pointsPerOnTime = 3;
}

enum UserRole { senior, family, worker, admin }

enum UserCapability {
  requester,
  serviceProvider,
  equipmentProvider,
  volunteer,
  trustContact,
}

enum OrderStatus { pending, accepted, inProgress, completed, cancelled }

enum OrderType {
  paramedical,
  transport,
  shopping,
  cleaning,
  plumbing,
  gardening,
  repair,
  toolSharing,
  volunteer,
  caregiving,
  housing,
}

enum VerificationStatus { unverified, pending, verified, rejected }

enum EquipmentStatus { available, reserved, inUse, returned, underReview }

enum EquipmentCondition { brandNew, likeNew, good, fair, worn }

enum EquipmentCategory {
  powerTools,
  handTools,
  gardenEquipment,
  cleaningEquipment,
  medicalAids,
  kitchenAppliances,
  sportEquipment,
  other,
}

enum PriceUnit { hour, day, week }

enum DisputeStatus { open, underReview, resolved, escalated, closed }

enum DisputeType { serviceQuality, equipmentDamage, payment, noShow, other }

enum PaymentStatus { pending, blocked, released, refunded, disputed }

enum AccessType { inPerson, keybox, digitalCode }

enum FriendshipStatus { pending, accepted, blocked }

enum NotificationType {
  reservationConfirmed,
  accessCodeDelivered,
  serviceStarted,
  serviceCompleted,
  overdueReturn,
  newMessage,
  verificationUpdate,
  disputeUpdate,
  friendRequest,
  badgeEarned,
  paymentUpdate,
}

enum ReviewCategory { serviceQuality, equipmentCondition, timeliness, trust }

extension UserCapabilityExtension on UserCapability {
  String get labelPl {
    switch (this) {
      case UserCapability.requester:
        return 'Zamawiający';
      case UserCapability.serviceProvider:
        return 'Usługodawca';
      case UserCapability.equipmentProvider:
        return 'Udostępniający sprzęt';
      case UserCapability.volunteer:
        return 'Wolontariusz';
      case UserCapability.trustContact:
        return 'Zaufana osoba';
    }
  }

  String get labelEn {
    switch (this) {
      case UserCapability.requester:
        return 'Requester';
      case UserCapability.serviceProvider:
        return 'Service Provider';
      case UserCapability.equipmentProvider:
        return 'Equipment Provider';
      case UserCapability.volunteer:
        return 'Volunteer';
      case UserCapability.trustContact:
        return 'Trust Contact';
    }
  }
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.senior:
        return 'Senior';
      case UserRole.family:
        return 'Rodzina / Opiekun';
      case UserRole.worker:
        return 'Wykonawca';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Oczekujące';
      case OrderStatus.accepted:
        return 'Zaakceptowane';
      case OrderStatus.inProgress:
        return 'W trakcie';
      case OrderStatus.completed:
        return 'Zakończone';
      case OrderStatus.cancelled:
        return 'Anulowane';
    }
  }
}

extension OrderTypeExtension on OrderType {
  String get label {
    switch (this) {
      case OrderType.paramedical:
        return 'Opieka paramedyczna';
      case OrderType.transport:
        return 'Transport';
      case OrderType.shopping:
        return 'Zakupy';
      case OrderType.cleaning:
        return 'Sprzątanie';
      case OrderType.plumbing:
        return 'Hydraulika';
      case OrderType.gardening:
        return 'Ogrodnictwo';
      case OrderType.repair:
        return 'Drobne naprawy';
      case OrderType.toolSharing:
        return 'Udostępnianie narzędzi';
      case OrderType.volunteer:
        return 'Wolontariat';
      case OrderType.caregiving:
        return 'Opieka domowa';
      case OrderType.housing:
        return 'Wymiana mieszkaniowa';
    }
  }

  String get icon {
    switch (this) {
      case OrderType.paramedical:
        return '🏥';
      case OrderType.transport:
        return '🚗';
      case OrderType.shopping:
        return '🛒';
      case OrderType.cleaning:
        return '🧹';
      case OrderType.plumbing:
        return '🔧';
      case OrderType.gardening:
        return '🌱';
      case OrderType.repair:
        return '🔨';
      case OrderType.toolSharing:
        return '🛠️';
      case OrderType.volunteer:
        return '🤝';
      case OrderType.caregiving:
        return '❤️';
      case OrderType.housing:
        return '🏠';
    }
  }

  bool get isFree => this == OrderType.volunteer;
}

extension EquipmentCategoryExtension on EquipmentCategory {
  String get label {
    switch (this) {
      case EquipmentCategory.powerTools:
        return 'Elektronarzędzia';
      case EquipmentCategory.handTools:
        return 'Narzędzia ręczne';
      case EquipmentCategory.gardenEquipment:
        return 'Sprzęt ogrodowy';
      case EquipmentCategory.cleaningEquipment:
        return 'Sprzęt do sprzątania';
      case EquipmentCategory.medicalAids:
        return 'Sprzęt medyczny';
      case EquipmentCategory.kitchenAppliances:
        return 'AGD kuchenne';
      case EquipmentCategory.sportEquipment:
        return 'Sprzęt sportowy';
      case EquipmentCategory.other:
        return 'Inne';
    }
  }

  String get icon {
    switch (this) {
      case EquipmentCategory.powerTools:
        return '⚡';
      case EquipmentCategory.handTools:
        return '🔧';
      case EquipmentCategory.gardenEquipment:
        return '🌿';
      case EquipmentCategory.cleaningEquipment:
        return '🧹';
      case EquipmentCategory.medicalAids:
        return '🩺';
      case EquipmentCategory.kitchenAppliances:
        return '🍳';
      case EquipmentCategory.sportEquipment:
        return '⚽';
      case EquipmentCategory.other:
        return '📦';
    }
  }
}

extension EquipmentStatusExtension on EquipmentStatus {
  String get label {
    switch (this) {
      case EquipmentStatus.available:
        return 'Dostępne';
      case EquipmentStatus.reserved:
        return 'Zarezerwowane';
      case EquipmentStatus.inUse:
        return 'W użyciu';
      case EquipmentStatus.returned:
        return 'Zwrócone';
      case EquipmentStatus.underReview:
        return 'W ocenie';
    }
  }
}

extension DisputeStatusExtension on DisputeStatus {
  String get label {
    switch (this) {
      case DisputeStatus.open:
        return 'Otwarte';
      case DisputeStatus.underReview:
        return 'W trakcie rozpatrywania';
      case DisputeStatus.resolved:
        return 'Rozwiązane';
      case DisputeStatus.escalated:
        return 'Eskalowane';
      case DisputeStatus.closed:
        return 'Zamknięte';
    }
  }
}

extension ReviewCategoryExtension on ReviewCategory {
  String get label {
    switch (this) {
      case ReviewCategory.serviceQuality:
        return 'Jakość usługi';
      case ReviewCategory.equipmentCondition:
        return 'Stan sprzętu';
      case ReviewCategory.timeliness:
        return 'Punktualność';
      case ReviewCategory.trust:
        return 'Zaufanie';
    }
  }
}
