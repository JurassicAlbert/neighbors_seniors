import '../database/database.dart';

class UserService {
  final AppDatabase database;

  UserService(this.database);

  Map<String, dynamic>? getUser(String id) {
    final results =
        database.db.select('SELECT * FROM users WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return _rowToUser(results.first);
  }

  List<Map<String, dynamic>> getAllUsers({String? role}) {
    if (role != null) {
      return database.db
          .select('SELECT * FROM users WHERE role = ? ORDER BY created_at DESC', [role])
          .map((row) => _rowToUser(row))
          .toList();
    }
    return database.db
        .select('SELECT * FROM users ORDER BY created_at DESC')
        .map((row) => _rowToUser(row))
        .toList();
  }

  Map<String, dynamic>? updateUser(String id, Map<String, dynamic> data) {
    final fields = <String>[];
    final values = <Object?>[];

    if (data.containsKey('name')) {
      fields.add('name = ?');
      values.add(data['name']);
    }
    if (data.containsKey('phone')) {
      fields.add('phone = ?');
      values.add(data['phone']);
    }
    if (data.containsKey('address')) {
      fields.add('address = ?');
      values.add(data['address']);
    }
    if (data.containsKey('lat')) {
      fields.add('lat = ?');
      values.add(data['lat']);
    }
    if (data.containsKey('lng')) {
      fields.add('lng = ?');
      values.add(data['lng']);
    }
    if (data.containsKey('verificationStatus')) {
      fields.add('verification_status = ?');
      values.add(data['verificationStatus']);
    }

    if (fields.isEmpty) return getUser(id);

    values.add(id);
    database.db.execute(
      'UPDATE users SET ${fields.join(', ')} WHERE id = ?',
      values,
    );
    return getUser(id);
  }

  List<Map<String, dynamic>> getPendingVerifications() {
    return database.db
        .select(
            "SELECT * FROM users WHERE verification_status = 'pending' AND role = 'worker' ORDER BY created_at DESC")
        .map((row) => _rowToUser(row))
        .toList();
  }

  Map<String, dynamic> _rowToUser(Map<String, dynamic> row) => {
        'id': row['id'],
        'email': row['email'],
        'name': row['name'],
        'phone': row['phone'],
        'role': row['role'],
        'avatarUrl': row['avatar_url'],
        'address': row['address'],
        'lat': row['lat'],
        'lng': row['lng'],
        'verificationStatus': row['verification_status'],
        'idDocumentUrl': row['id_document_url'],
        'selfieUrl': row['selfie_url'],
        'createdAt': row['created_at'],
      };
}
