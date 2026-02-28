import 'package:sqlite3/sqlite3.dart';

class AppDatabase {
  late final Database _db;

  AppDatabase({String path = 'neighbors_seniors.db'}) {
    _db = sqlite3.open(path);
    _createTables();
    _seedData();
  }

  Database get db => _db;

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        role TEXT NOT NULL DEFAULT 'senior',
        avatar_url TEXT,
        address TEXT,
        lat REAL,
        lng REAL,
        verification_status TEXT NOT NULL DEFAULT 'unverified',
        id_document_url TEXT,
        selfie_url TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'pending',
        requester_id TEXT NOT NULL,
        worker_id TEXT,
        senior_id TEXT,
        price REAL,
        commission REAL,
        deposit REAL,
        address TEXT NOT NULL DEFAULT '',
        lat REAL,
        lng REAL,
        scheduled_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (requester_id) REFERENCES users(id),
        FOREIGN KEY (worker_id) REFERENCES users(id)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS reviews (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        reviewer_id TEXT NOT NULL,
        reviewee_id TEXT NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id),
        FOREIGN KEY (reviewer_id) REFERENCES users(id),
        FOREIGN KEY (reviewee_id) REFERENCES users(id)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        read INTEGER NOT NULL DEFAULT 0,
        order_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS location_logs (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        worker_id TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id),
        FOREIGN KEY (worker_id) REFERENCES users(id)
      )
    ''');
  }

  void _seedData() {
    final result = _db.select('SELECT COUNT(*) as cnt FROM users');
    if (result.first['cnt'] as int > 0) return;

    // Seed is handled by the auth service when users register
  }

  void close() {
    _db.dispose();
  }
}
