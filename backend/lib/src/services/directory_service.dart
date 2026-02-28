import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../database/database.dart';

const _uuid = Uuid();

class DirectoryService {
  final AppDatabase database;

  DirectoryService(this.database);

  Map<String, dynamic> createOffer({
    required String providerId,
    required String title,
    String description = '',
    required String serviceType,
    double? priceFrom,
    double? priceTo,
    String? location,
    double? lat,
    double? lng,
    double? radiusKm,
    List<String> skills = const [],
    String? availabilitySchedule,
  }) {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    database.db.execute(
      '''INSERT INTO service_offers (id, provider_id, title, description, service_type,
         price_from, price_to, location, lat, lng, radius_km, skills,
         availability_schedule, is_active, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id, providerId, title, description, serviceType,
        priceFrom, priceTo, location, lat, lng, radiusKm,
        jsonEncode(skills), availabilitySchedule, 1, now, now,
      ],
    );
    return getOffer(id)!;
  }

  Map<String, dynamic>? getOffer(String id) {
    final results = database.db.select('''
      SELECT s.*, u.name as provider_name, u.email as provider_email, u.phone as provider_phone
      FROM service_offers s
      LEFT JOIN users u ON s.provider_id = u.id
      WHERE s.id = ?
    ''', [id]);
    if (results.isEmpty) return null;
    return _rowToOffer(results.first);
  }

  List<Map<String, dynamic>> listOffers({
    String? type,
    String? location,
    List<String>? skills,
    int limit = 50,
    int offset = 0,
  }) {
    var query = '''
      SELECT s.*, u.name as provider_name, u.email as provider_email, u.phone as provider_phone
      FROM service_offers s
      LEFT JOIN users u ON s.provider_id = u.id
    ''';
    final conditions = <String>['s.is_active = 1'];
    final params = <Object?>[];

    if (type != null) {
      conditions.add('s.service_type = ?');
      params.add(type);
    }
    if (location != null) {
      conditions.add('s.location LIKE ?');
      params.add('%$location%');
    }

    query += ' WHERE ${conditions.join(' AND ')}';
    query += ' ORDER BY s.created_at DESC LIMIT ? OFFSET ?';
    params.addAll([limit, offset]);

    var results = database.db.select(query, params).map((row) => _rowToOffer(row)).toList();

    if (skills != null && skills.isNotEmpty) {
      results = results.where((offer) {
        final offerSkills = (offer['skills'] as List<dynamic>).cast<String>();
        return skills.any((s) => offerSkills.contains(s));
      }).toList();
    }

    return results;
  }

  List<Map<String, dynamic>> searchOffers({
    String? query,
    String? type,
    double? lat,
    double? lng,
    double? radiusKm,
    int limit = 50,
    int offset = 0,
  }) {
    var sql = '''
      SELECT s.*, u.name as provider_name, u.email as provider_email, u.phone as provider_phone
      FROM service_offers s
      LEFT JOIN users u ON s.provider_id = u.id
    ''';
    final conditions = <String>['s.is_active = 1'];
    final params = <Object?>[];

    if (type != null) {
      conditions.add('s.service_type = ?');
      params.add(type);
    }
    if (query != null && query.isNotEmpty) {
      conditions.add('(s.title LIKE ? OR s.description LIKE ?)');
      params.add('%$query%');
      params.add('%$query%');
    }

    sql += ' WHERE ${conditions.join(' AND ')}';
    sql += ' ORDER BY s.created_at DESC LIMIT ? OFFSET ?';
    params.addAll([limit, offset]);

    var results = database.db.select(sql, params).map((row) => _rowToOffer(row)).toList();

    if (lat != null && lng != null && radiusKm != null) {
      results = results.where((offer) {
        final oLat = offer['lat'] as double?;
        final oLng = offer['lng'] as double?;
        if (oLat == null || oLng == null) return true;
        final dist = _haversineDistance(lat, lng, oLat, oLng);
        return dist <= radiusKm;
      }).toList();
    }

    return results;
  }

  Map<String, dynamic>? updateOffer(String id, Map<String, dynamic> data) {
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
    if (data.containsKey('serviceType')) {
      fields.add('service_type = ?');
      values.add(data['serviceType']);
    }
    if (data.containsKey('priceFrom')) {
      fields.add('price_from = ?');
      values.add(data['priceFrom']);
    }
    if (data.containsKey('priceTo')) {
      fields.add('price_to = ?');
      values.add(data['priceTo']);
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
    if (data.containsKey('radiusKm')) {
      fields.add('radius_km = ?');
      values.add(data['radiusKm']);
    }
    if (data.containsKey('skills')) {
      fields.add('skills = ?');
      values.add(jsonEncode(data['skills']));
    }
    if (data.containsKey('availabilitySchedule')) {
      fields.add('availability_schedule = ?');
      values.add(data['availabilitySchedule']);
    }

    if (fields.isEmpty) return getOffer(id);

    fields.add('updated_at = ?');
    values.add(DateTime.now().toIso8601String());
    values.add(id);

    database.db.execute(
      'UPDATE service_offers SET ${fields.join(', ')} WHERE id = ?',
      values,
    );
    return getOffer(id);
  }

  Map<String, dynamic>? deactivateOffer(String id) {
    final now = DateTime.now().toIso8601String();
    database.db.execute(
      'UPDATE service_offers SET is_active = 0, updated_at = ? WHERE id = ?',
      [now, id],
    );
    return getOffer(id);
  }

  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * pi / 180;

  Map<String, dynamic> _rowToOffer(Map<String, dynamic> row) {
    List<dynamic> skills = [];
    if (row['skills'] != null) {
      try {
        skills = jsonDecode(row['skills'] as String) as List<dynamic>;
      } catch (_) {}
    }

    final offer = <String, dynamic>{
      'id': row['id'],
      'providerId': row['provider_id'],
      'title': row['title'],
      'description': row['description'],
      'serviceType': row['service_type'],
      'priceFrom': row['price_from'],
      'priceTo': row['price_to'],
      'location': row['location'],
      'lat': row['lat'],
      'lng': row['lng'],
      'radiusKm': row['radius_km'],
      'skills': skills,
      'availabilitySchedule': row['availability_schedule'],
      'isActive': (row['is_active'] as int) == 1,
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };

    if (row['provider_name'] != null) {
      offer['provider'] = {
        'id': row['provider_id'],
        'name': row['provider_name'],
        'email': row['provider_email'],
        'phone': row['provider_phone'],
      };
    }

    return offer;
  }
}
