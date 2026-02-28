import 'package:uuid/uuid.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../database/database.dart';

const _uuid = Uuid();

class OrderService {
  final AppDatabase database;

  OrderService(this.database);

  Map<String, dynamic> createOrder({
    required String type,
    required String title,
    required String description,
    required String requesterId,
    String? seniorId,
    double? price,
    double? deposit,
    required String address,
    double? lat,
    double? lng,
    String? scheduledAt,
  }) {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final commission =
        price != null ? price * AppConstants.platformCommissionRate : null;

    database.db.execute(
      '''INSERT INTO orders (id, type, title, description, status, requester_id, senior_id, 
         price, commission, deposit, address, lat, lng, scheduled_at, created_at, updated_at) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id, type, title, description, 'pending', requesterId, seniorId,
        price, commission, deposit, address, lat, lng, scheduledAt, now, now,
      ],
    );
    return getOrder(id)!;
  }

  Map<String, dynamic>? getOrder(String id) {
    final results = database.db.select('''
      SELECT o.*, 
             r.name as requester_name, r.email as requester_email, r.phone as requester_phone, r.role as requester_role, r.created_at as requester_created_at,
             w.name as worker_name, w.email as worker_email, w.phone as worker_phone, w.role as worker_role, w.created_at as worker_created_at
      FROM orders o 
      LEFT JOIN users r ON o.requester_id = r.id
      LEFT JOIN users w ON o.worker_id = w.id
      WHERE o.id = ?
    ''', [id]);
    if (results.isEmpty) return null;
    return _rowToOrder(results.first);
  }

  List<Map<String, dynamic>> getOrders({
    String? requesterId,
    String? workerId,
    String? status,
    String? type,
    int limit = 50,
    int offset = 0,
  }) {
    var query = '''
      SELECT o.*, 
             r.name as requester_name, r.email as requester_email, r.phone as requester_phone, r.role as requester_role, r.created_at as requester_created_at,
             w.name as worker_name, w.email as worker_email, w.phone as worker_phone, w.role as worker_role, w.created_at as worker_created_at
      FROM orders o 
      LEFT JOIN users r ON o.requester_id = r.id
      LEFT JOIN users w ON o.worker_id = w.id
    ''';
    final conditions = <String>[];
    final params = <Object?>[];

    if (requesterId != null) {
      conditions.add('o.requester_id = ?');
      params.add(requesterId);
    }
    if (workerId != null) {
      conditions.add('o.worker_id = ?');
      params.add(workerId);
    }
    if (status != null) {
      conditions.add('o.status = ?');
      params.add(status);
    }
    if (type != null) {
      conditions.add('o.type = ?');
      params.add(type);
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }
    query += ' ORDER BY o.created_at DESC LIMIT ? OFFSET ?';
    params.addAll([limit, offset]);

    return database.db.select(query, params).map((row) => _rowToOrder(row)).toList();
  }

  List<Map<String, dynamic>> getAvailableOrders({int limit = 50, int offset = 0}) {
    return database.db.select('''
      SELECT o.*, 
             r.name as requester_name, r.email as requester_email, r.phone as requester_phone, r.role as requester_role, r.created_at as requester_created_at,
             w.name as worker_name, w.email as worker_email, w.phone as worker_phone, w.role as worker_role, w.created_at as worker_created_at
      FROM orders o 
      LEFT JOIN users r ON o.requester_id = r.id
      LEFT JOIN users w ON o.worker_id = w.id
      WHERE o.status = 'pending' AND o.worker_id IS NULL
      ORDER BY o.created_at DESC LIMIT ? OFFSET ?
    ''', [limit, offset]).map((row) => _rowToOrder(row)).toList();
  }

  Map<String, dynamic>? updateOrderStatus(String id, String status, {String? workerId}) {
    final now = DateTime.now().toIso8601String();
    if (workerId != null) {
      database.db.execute(
        'UPDATE orders SET status = ?, worker_id = ?, updated_at = ? WHERE id = ?',
        [status, workerId, now, id],
      );
    } else {
      database.db.execute(
        'UPDATE orders SET status = ?, updated_at = ? WHERE id = ?',
        [status, now, id],
      );
    }
    return getOrder(id);
  }

  Map<String, dynamic> _rowToOrder(Map<String, dynamic> row) {
    final order = <String, dynamic>{
      'id': row['id'],
      'type': row['type'],
      'title': row['title'],
      'description': row['description'],
      'status': row['status'],
      'requesterId': row['requester_id'],
      'workerId': row['worker_id'],
      'seniorId': row['senior_id'],
      'price': row['price'],
      'commission': row['commission'],
      'deposit': row['deposit'],
      'address': row['address'],
      'lat': row['lat'],
      'lng': row['lng'],
      'scheduledAt': row['scheduled_at'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };

    if (row['requester_name'] != null) {
      order['requester'] = {
        'id': row['requester_id'],
        'email': row['requester_email'],
        'name': row['requester_name'],
        'phone': row['requester_phone'],
        'role': row['requester_role'],
        'createdAt': row['requester_created_at'],
      };
    }
    if (row['worker_name'] != null) {
      order['worker'] = {
        'id': row['worker_id'],
        'email': row['worker_email'],
        'name': row['worker_name'],
        'phone': row['worker_phone'],
        'role': row['worker_role'],
        'createdAt': row['worker_created_at'],
      };
    }

    return order;
  }
}
