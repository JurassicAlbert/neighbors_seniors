import 'dart:math';
import 'package:uuid/uuid.dart';
import '../database/database.dart';

const _uuid = Uuid();
final _random = Random();

class SocialService {
  final AppDatabase database;

  SocialService(this.database);

  // --- Friends ---

  Map<String, dynamic> sendFriendRequest({
    required String userId,
    required String friendId,
    String? tag,
  }) {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    database.db.execute(
      'INSERT INTO friendships (id, user_id, friend_id, status, tag, created_at) VALUES (?, ?, ?, ?, ?, ?)',
      [id, userId, friendId, 'pending', tag, now],
    );
    return getFriendship(id)!;
  }

  Map<String, dynamic>? getFriendship(String id) {
    final results = database.db.select('''
      SELECT f.*, u.name as friend_name, u.email as friend_email
      FROM friendships f
      LEFT JOIN users u ON f.friend_id = u.id
      WHERE f.id = ?
    ''', [id]);
    if (results.isEmpty) return null;
    return _rowToFriendship(results.first);
  }

  Map<String, dynamic>? acceptFriendRequest(String id) {
    database.db.execute(
      "UPDATE friendships SET status = 'accepted' WHERE id = ?",
      [id],
    );
    return getFriendship(id);
  }

  bool removeFriend(String id) {
    database.db.execute('DELETE FROM friendships WHERE id = ?', [id]);
    return true;
  }

  List<Map<String, dynamic>> listFriends(String userId) {
    return database.db.select('''
      SELECT f.*, u.name as friend_name, u.email as friend_email
      FROM friendships f
      LEFT JOIN users u ON f.friend_id = u.id
      WHERE f.user_id = ? AND f.status = 'accepted'
      ORDER BY f.created_at DESC
    ''', [userId]).map((row) => _rowToFriendship(row)).toList();
  }

  List<Map<String, dynamic>> listFriendRequests(String userId) {
    return database.db.select('''
      SELECT f.*, u.name as friend_name, u.email as friend_email
      FROM friendships f
      LEFT JOIN users u ON f.user_id = u.id
      WHERE f.friend_id = ? AND f.status = 'pending'
      ORDER BY f.created_at DESC
    ''', [userId]).map((row) => _rowToFriendship(row)).toList();
  }

  // --- Badges ---

  List<Map<String, dynamic>> listBadges() {
    return database.db
        .select('SELECT * FROM badges ORDER BY required_points ASC')
        .map((row) => _rowToBadge(row))
        .toList();
  }

  List<Map<String, dynamic>> getUserBadges(String userId) {
    return database.db.select('''
      SELECT b.*, ub.earned_at
      FROM user_badges ub
      JOIN badges b ON ub.badge_id = b.id
      WHERE ub.user_id = ?
      ORDER BY ub.earned_at DESC
    ''', [userId]).map((row) => _rowToBadge(row)).toList();
  }

  Map<String, dynamic>? awardBadge(String userId, String badgeId) {
    final now = DateTime.now().toIso8601String();
    final existing = database.db.select(
      'SELECT * FROM user_badges WHERE user_id = ? AND badge_id = ?',
      [userId, badgeId],
    );
    if (existing.isNotEmpty) return null;

    database.db.execute(
      'INSERT INTO user_badges (user_id, badge_id, earned_at) VALUES (?, ?, ?)',
      [userId, badgeId, now],
    );
    final badge = database.db.select('SELECT * FROM badges WHERE id = ?', [badgeId]);
    if (badge.isEmpty) return null;
    return _rowToBadge(badge.first);
  }

  // --- Access Codes ---

  Map<String, dynamic> createAccessCode({
    required String orderId,
    required String granterId,
    String? recipientId,
    required String accessType,
    String? instructions,
    required String expiresAt,
  }) {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final code = _generateCode();

    database.db.execute(
      '''INSERT INTO access_codes (id, order_id, granter_id, recipient_id, code, access_type,
         instructions, expires_at, used, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [id, orderId, granterId, recipientId, code, accessType, instructions, expiresAt, 0, now],
    );
    return getAccessCode(id)!;
  }

  Map<String, dynamic>? getAccessCode(String id) {
    final results = database.db.select(
      'SELECT * FROM access_codes WHERE id = ?', [id],
    );
    if (results.isEmpty) return null;
    return _rowToAccessCode(results.first);
  }

  bool markAccessCodeUsed(String id) {
    database.db.execute('UPDATE access_codes SET used = 1 WHERE id = ?', [id]);
    return true;
  }

  List<Map<String, dynamic>> listAccessCodes(String orderId) {
    return database.db
        .select('SELECT * FROM access_codes WHERE order_id = ? ORDER BY created_at DESC', [orderId])
        .map((row) => _rowToAccessCode(row))
        .toList();
  }

  // --- Check-in ---

  Map<String, dynamic> logCheckIn({
    required String orderId,
    required String userId,
    required bool isCheckIn,
    double? lat,
    double? lng,
  }) {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    database.db.execute(
      'INSERT INTO check_in_logs (id, order_id, user_id, is_check_in, lat, lng, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, orderId, userId, isCheckIn ? 1 : 0, lat, lng, now],
    );

    final field = isCheckIn ? 'checked_in_at' : 'checked_out_at';
    database.db.execute(
      'UPDATE orders SET $field = ?, updated_at = ? WHERE id = ?',
      [now, now, orderId],
    );

    return getCheckInLog(id)!;
  }

  Map<String, dynamic>? getCheckInLog(String id) {
    final results = database.db.select(
      'SELECT * FROM check_in_logs WHERE id = ?', [id],
    );
    if (results.isEmpty) return null;
    return _rowToCheckIn(results.first);
  }

  List<Map<String, dynamic>> getCheckInLogs(String orderId) {
    return database.db
        .select('SELECT * FROM check_in_logs WHERE order_id = ? ORDER BY timestamp ASC', [orderId])
        .map((row) => _rowToCheckIn(row))
        .toList();
  }

  // --- Points ---

  Map<String, dynamic>? addPoints(String userId, int points) {
    final user = database.db.select('SELECT points FROM users WHERE id = ?', [userId]);
    if (user.isEmpty) return null;

    final currentPoints = user.first['points'] as int? ?? 0;
    final newPoints = currentPoints + points;
    final newLevel = newPoints ~/ 100 + 1;

    database.db.execute(
      'UPDATE users SET points = ?, level = ? WHERE id = ?',
      [newPoints, newLevel, userId],
    );

    final updated = database.db.select('SELECT * FROM users WHERE id = ?', [userId]);
    if (updated.isEmpty) return null;
    return {
      'id': updated.first['id'],
      'points': updated.first['points'],
      'level': updated.first['level'],
    };
  }

  // --- Helpers ---

  String _generateCode() {
    return List.generate(6, (_) => _random.nextInt(10)).join();
  }

  Map<String, dynamic> _rowToFriendship(Map<String, dynamic> row) {
    final friendship = <String, dynamic>{
      'id': row['id'],
      'userId': row['user_id'],
      'friendId': row['friend_id'],
      'status': row['status'],
      'tag': row['tag'],
      'createdAt': row['created_at'],
    };
    if (row['friend_name'] != null) {
      friendship['friend'] = {
        'id': row['friend_id'],
        'name': row['friend_name'],
        'email': row['friend_email'],
      };
    }
    return friendship;
  }

  Map<String, dynamic> _rowToBadge(Map<String, dynamic> row) => {
        'id': row['id'],
        'name': row['name'],
        'description': row['description'],
        'icon': row['icon'],
        'requiredPoints': row['required_points'],
        'category': row['category'],
        if (row.containsKey('earned_at')) 'earnedAt': row['earned_at'],
      };

  Map<String, dynamic> _rowToAccessCode(Map<String, dynamic> row) => {
        'id': row['id'],
        'orderId': row['order_id'],
        'granterId': row['granter_id'],
        'recipientId': row['recipient_id'],
        'code': row['code'],
        'accessType': row['access_type'],
        'instructions': row['instructions'],
        'expiresAt': row['expires_at'],
        'used': (row['used'] as int) == 1,
        'createdAt': row['created_at'],
      };

  Map<String, dynamic> _rowToCheckIn(Map<String, dynamic> row) => {
        'id': row['id'],
        'orderId': row['order_id'],
        'userId': row['user_id'],
        'isCheckIn': (row['is_check_in'] as int) == 1,
        'lat': row['lat'],
        'lng': row['lng'],
        'timestamp': row['timestamp'],
      };
}
