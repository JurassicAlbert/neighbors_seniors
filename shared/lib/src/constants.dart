class AppConstants {
  static const String appName = 'Sąsiedzi & Seniorzy';
  static const String appNameEn = 'Neighbors & Seniors';
  static const double platformCommissionRate = 0.10;
  static const int maxRating = 5;
  static const int minPasswordLength = 8;
}

enum UserRole { senior, family, worker, admin }

enum OrderStatus { pending, accepted, inProgress, completed, cancelled }

enum OrderType { paramedical, transport, shopping, cleaning, plumbing, gardening, repair, toolSharing, volunteer }

enum VerificationStatus { unverified, pending, verified, rejected }

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
    }
  }

  bool get isFree => this == OrderType.volunteer;
}
