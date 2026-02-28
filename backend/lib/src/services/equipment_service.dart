import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database.dart';

const _uuid = Uuid();

class EquipmentService {
  final AppDatabase database;

  EquipmentService(this.database);

  Map<String, dynamic> createEquipment({
    required String ownerId,
    required String title,
    String description = '',
    required String category,
    String condition = 'good',
    List<String> photoUrls = const [],
    double pricePerUnit = 0,
    String priceUnit = 'day',
    double? depositAmount,
    String? location,
    double? lat,
    double? lng,
    bool isRecurring = false,
    String? availabilitySchedule,
  }) {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    database.db.execute(
      '''INSERT INTO equipment (id, owner_id, title, description, category, condition, status,
         photo_urls, price_per_unit, price_unit, deposit_amount, location, lat, lng,
         is_recurring, availability_schedule, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id, ownerId, title, description, category, condition, 'available',
        jsonEncode(photoUrls), pricePerUnit, priceUnit, depositAmount,
        location, lat, lng, isRecurring ? 1 : 0, availabilitySchedule, now, now,
      ],
    );
    return getEquipment(id)!;
  }

  Map<String, dynamic>? getEquipment(String id) {
    final results = database.db.select('''
      SELECT e.*, u.name as owner_name, u.email as owner_email, u.phone as owner_phone
      FROM equipment e
      LEFT JOIN users u ON e.owner_id = u.id
      WHERE e.id = ?
    ''', [id]);
    if (results.isEmpty) return null;
    return _rowToEquipment(results.first);
  }

  List<Map<String, dynamic>> listEquipment({
    String? category,
    String? status,
    String? ownerId,
    int limit = 50,
    int offset = 0,
  }) {
    var query = '''
      SELECT e.*, u.name as owner_name, u.email as owner_email, u.phone as owner_phone
      FROM equipment e
      LEFT JOIN users u ON e.owner_id = u.id
    ''';
    final conditions = <String>[];
    final params = <Object?>[];

    if (category != null) {
      conditions.add('e.category = ?');
      params.add(category);
    }
    if (status != null) {
      conditions.add('e.status = ?');
      params.add(status);
    }
    if (ownerId != null) {
      conditions.add('e.owner_id = ?');
      params.add(ownerId);
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }
    query += ' ORDER BY e.created_at DESC LIMIT ? OFFSET ?';
    params.addAll([limit, offset]);

    return database.db.select(query, params).map((row) => _rowToEquipment(row)).toList();
  }

  Map<String, dynamic>? updateEquipment(String id, Map<String, dynamic> data) {
    final fields = <String>[];
    final values = <Object?>[];

    if (data.containsKey('title')) {
      fields.add('title = ?');
      values.add(data['title']);
    }
    if (data.containsKey('description')) {
      fields.add('description = ?');
      values.add(data['description']);
    }
    if (data.containsKey('category')) {
      fields.add('category = ?');
      values.add(data['category']);
    }
    if (data.containsKey('condition')) {
      fields.add('condition = ?');
      values.add(data['condition']);
    }
    if (data.containsKey('status')) {
      fields.add('status = ?');
      values.add(data['status']);
    }
    if (data.containsKey('photoUrls')) {
      fields.add('photo_urls = ?');
      values.add(jsonEncode(data['photoUrls']));
    }
    if (data.containsKey('pricePerUnit')) {
      fields.add('price_per_unit = ?');
      values.add(data['pricePerUnit']);
    }
    if (data.containsKey('priceUnit')) {
      fields.add('price_unit = ?');
      values.add(data['priceUnit']);
    }
    if (data.containsKey('depositAmount')) {
      fields.add('deposit_amount = ?');
      values.add(data['depositAmount']);
    }
    if (data.containsKey('location')) {
      fields.add('location = ?');
      values.add(data['location']);
    }
    if (data.containsKey('lat')) {
      fields.add('lat = ?');
      values.add(data['lat']);
    }
    if (data.containsKey('lng')) {
      fields.add('lng = ?');
      values.add(data['lng']);
    }

    if (fields.isEmpty) return getEquipment(id);

    fields.add('updated_at = ?');
    values.add(DateTime.now().toIso8601String());
    values.add(id);

    database.db.execute(
      'UPDATE equipment SET ${fields.join(', ')} WHERE id = ?',
      values,
    );
    return getEquipment(id);
  }

  bool deleteEquipment(String id) {
    database.db.execute('DELETE FROM equipment WHERE id = ?', [id]);
    return true;
  }

  // --- Reservations ---

  Map<String, dynamic> createReservation({
    required String equipmentId,
    required String borrowerId,
    required String ownerId,
    required String startDate,
    required String endDate,
    required double totalPrice,
    double? depositAmount,
    String? notes,
  }) {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    database.db.execute(
      '''INSERT INTO equipment_reservations (id, equipment_id, borrower_id, owner_id, status,
         start_date, end_date, total_price, deposit_amount, notes, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id, equipmentId, borrowerId, ownerId, 'reserved',
        startDate, endDate, totalPrice, depositAmount, notes, now, now,
      ],
    );

    database.db.execute(
      "UPDATE equipment SET status = 'reserved', updated_at = ? WHERE id = ?",
      [now, equipmentId],
    );

    return getReservation(id)!;
  }

  Map<String, dynamic>? getReservation(String id) {
    final results = database.db.select('''
      SELECT r.*, e.title as equipment_title, e.category as equipment_category,
             u.name as borrower_name, u.email as borrower_email
      FROM equipment_reservations r
      LEFT JOIN equipment e ON r.equipment_id = e.id
      LEFT JOIN users u ON r.borrower_id = u.id
      WHERE r.id = ?
    ''', [id]);
    if (results.isEmpty) return null;
    return _rowToReservation(results.first);
  }

  List<Map<String, dynamic>> listReservations({
    String? borrowerId,
    String? ownerId,
    String? equipmentId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) {
    var query = '''
      SELECT r.*, e.title as equipment_title, e.category as equipment_category,
             u.name as borrower_name, u.email as borrower_email
      FROM equipment_reservations r
      LEFT JOIN equipment e ON r.equipment_id = e.id
      LEFT JOIN users u ON r.borrower_id = u.id
    ''';
    final conditions = <String>[];
    final params = <Object?>[];

    if (borrowerId != null) {
      conditions.add('r.borrower_id = ?');
      params.add(borrowerId);
    }
    if (ownerId != null) {
      conditions.add('r.owner_id = ?');
      params.add(ownerId);
    }
    if (equipmentId != null) {
      conditions.add('r.equipment_id = ?');
      params.add(equipmentId);
    }
    if (status != null) {
      conditions.add('r.status = ?');
      params.add(status);
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }
    query += ' ORDER BY r.created_at DESC LIMIT ? OFFSET ?';
    params.addAll([limit, offset]);

    return database.db.select(query, params).map((row) => _rowToReservation(row)).toList();
  }

  Map<String, dynamic>? updateReservationStatus(String id, String status) {
    final now = DateTime.now().toIso8601String();
    database.db.execute(
      'UPDATE equipment_reservations SET status = ?, updated_at = ? WHERE id = ?',
      [status, now, id],
    );

    final reservation = getReservation(id);
    if (reservation != null) {
      final equipmentId = reservation['equipmentId'] as String;
      String equipmentStatus;
      switch (status) {
        case 'inUse':
          equipmentStatus = 'inUse';
          break;
        case 'returned':
          equipmentStatus = 'available';
          break;
        default:
          equipmentStatus = 'reserved';
      }
      database.db.execute(
        'UPDATE equipment SET status = ?, updated_at = ? WHERE id = ?',
        [equipmentStatus, now, equipmentId],
      );
    }

    return reservation;
  }

  Map<String, dynamic> _rowToEquipment(Map<String, dynamic> row) {
    List<dynamic> photoUrls = [];
    if (row['photo_urls'] != null) {
      try {
        photoUrls = jsonDecode(row['photo_urls'] as String) as List<dynamic>;
      } catch (_) {}
    }

    final equipment = <String, dynamic>{
      'id': row['id'],
      'ownerId': row['owner_id'],
      'title': row['title'],
      'description': row['description'],
      'category': row['category'],
      'condition': row['condition'],
      'status': row['status'],
      'photoUrls': photoUrls,
      'pricePerUnit': row['price_per_unit'],
      'priceUnit': row['price_unit'],
      'depositAmount': row['deposit_amount'],
      'location': row['location'],
      'lat': row['lat'],
      'lng': row['lng'],
      'isRecurring': (row['is_recurring'] as int) == 1,
      'availabilitySchedule': row['availability_schedule'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };

    if (row['owner_name'] != null) {
      equipment['owner'] = {
        'id': row['owner_id'],
        'name': row['owner_name'],
        'email': row['owner_email'],
        'phone': row['owner_phone'],
      };
    }

    return equipment;
  }

  Map<String, dynamic> _rowToReservation(Map<String, dynamic> row) {
    final reservation = <String, dynamic>{
      'id': row['id'],
      'equipmentId': row['equipment_id'],
      'borrowerId': row['borrower_id'],
      'ownerId': row['owner_id'],
      'status': row['status'],
      'startDate': row['start_date'],
      'endDate': row['end_date'],
      'totalPrice': row['total_price'],
      'depositAmount': row['deposit_amount'],
      'notes': row['notes'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };

    if (row['equipment_title'] != null) {
      reservation['equipment'] = {
        'id': row['equipment_id'],
        'title': row['equipment_title'],
        'category': row['equipment_category'],
      };
    }
    if (row['borrower_name'] != null) {
      reservation['borrower'] = {
        'id': row['borrower_id'],
        'name': row['borrower_name'],
        'email': row['borrower_email'],
      };
    }

    return reservation;
  }
}
