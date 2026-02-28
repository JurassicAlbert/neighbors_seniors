import '../database/database.dart';

class StatsService {
  final AppDatabase database;

  StatsService(this.database);

  Map<String, dynamic> getStats() {
    final totalUsers =
        database.db.select('SELECT COUNT(*) as cnt FROM users').first['cnt'] as int;
    final totalOrders =
        database.db.select('SELECT COUNT(*) as cnt FROM orders').first['cnt'] as int;
    final activeOrders = database.db
        .select("SELECT COUNT(*) as cnt FROM orders WHERE status IN ('pending', 'accepted', 'inProgress')")
        .first['cnt'] as int;
    final completedOrders = database.db
        .select("SELECT COUNT(*) as cnt FROM orders WHERE status = 'completed'")
        .first['cnt'] as int;

    final revenueResult = database.db.select(
        "SELECT COALESCE(SUM(price), 0) as total FROM orders WHERE status = 'completed'");
    final totalRevenue = (revenueResult.first['total'] as num).toDouble();

    final commissionResult = database.db.select(
        "SELECT COALESCE(SUM(commission), 0) as total FROM orders WHERE status = 'completed'");
    final totalCommission = (commissionResult.first['total'] as num).toDouble();

    final verifiedWorkers = database.db
        .select(
            "SELECT COUNT(*) as cnt FROM users WHERE role = 'worker' AND verification_status = 'verified'")
        .first['cnt'] as int;

    final pendingVerifications = database.db
        .select(
            "SELECT COUNT(*) as cnt FROM users WHERE role = 'worker' AND verification_status = 'pending'")
        .first['cnt'] as int;

    final ordersByType = <String, int>{};
    final typeResults =
        database.db.select('SELECT type, COUNT(*) as cnt FROM orders GROUP BY type');
    for (final row in typeResults) {
      ordersByType[row['type'] as String] = row['cnt'] as int;
    }

    final totalEquipment =
        database.db.select('SELECT COUNT(*) as cnt FROM equipment').first['cnt'] as int;
    final activeReservations = database.db
        .select("SELECT COUNT(*) as cnt FROM equipment_reservations WHERE status IN ('reserved', 'inUse')")
        .first['cnt'] as int;
    final openDisputes = database.db
        .select("SELECT COUNT(*) as cnt FROM disputes WHERE status IN ('open', 'underReview')")
        .first['cnt'] as int;
    final totalFriendships = database.db
        .select("SELECT COUNT(*) as cnt FROM friendships WHERE status = 'accepted'")
        .first['cnt'] as int;

    return {
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
  }
}
