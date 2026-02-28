import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';

const _jwtSecret = 'neighbors-seniors-jwt-secret-key-change-in-production';
const _uuid = Uuid();

class AuthService {
  final AppDatabase database;

  AuthService(this.database);

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  String _generateToken(String userId, String role) {
    final jwt = JWT({'userId': userId, 'role': role});
    return jwt.sign(SecretKey(_jwtSecret), expiresIn: const Duration(days: 30));
  }

  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      return jwt.payload as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) {
    final existing =
        database.db.select('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.isNotEmpty) return null;

    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final hash = _hashPassword(password);

    database.db.execute(
      'INSERT INTO users (id, email, password_hash, name, phone, role, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, email, hash, name, phone, role, now],
    );

    final user = _getUserById(id);
    if (user == null) return null;

    final token = _generateToken(id, role);
    return {'token': token, 'user': user};
  }

  Map<String, dynamic>? login({
    required String email,
    required String password,
  }) {
    final hash = _hashPassword(password);
    final results = database.db.select(
      'SELECT * FROM users WHERE email = ? AND password_hash = ?',
      [email, hash],
    );
    if (results.isEmpty) return null;

    final row = results.first;
    final user = _rowToUser(row);
    final token = _generateToken(row['id'] as String, row['role'] as String);
    return {'token': token, 'user': user};
  }

  Map<String, dynamic>? _getUserById(String id) {
    final results = database.db.select('SELECT * FROM users WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return _rowToUser(results.first);
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
