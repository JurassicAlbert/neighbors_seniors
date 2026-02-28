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
        capabilities TEXT DEFAULT '["requester"]',
        points INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Add new columns to users if migrating from v1
    _addColumnIfNotExists('users', 'capabilities', "TEXT DEFAULT '[\"requester\"]'");
    _addColumnIfNotExists('users', 'points', 'INTEGER NOT NULL DEFAULT 0');
    _addColumnIfNotExists('users', 'level', 'INTEGER NOT NULL DEFAULT 1');

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
        access_type TEXT,
        access_code TEXT,
        checked_in_at TEXT,
        checked_out_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (requester_id) REFERENCES users(id),
        FOREIGN KEY (worker_id) REFERENCES users(id)
      )
    ''');

    // Add new columns to orders if migrating from v1
    _addColumnIfNotExists('orders', 'access_type', 'TEXT');
    _addColumnIfNotExists('orders', 'access_code', 'TEXT');
    _addColumnIfNotExists('orders', 'checked_in_at', 'TEXT');
    _addColumnIfNotExists('orders', 'checked_out_at', 'TEXT');

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

    // --- v2 tables ---

    _db.execute('''
      CREATE TABLE IF NOT EXISTS equipment (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        condition TEXT NOT NULL DEFAULT 'good',
        status TEXT NOT NULL DEFAULT 'available',
        photo_urls TEXT DEFAULT '[]',
        price_per_unit REAL NOT NULL DEFAULT 0,
        price_unit TEXT NOT NULL DEFAULT 'day',
        deposit_amount REAL,
        location TEXT,
        lat REAL, lng REAL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        availability_schedule TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users(id)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS equipment_reservations (
        id TEXT PRIMARY KEY,
        equipment_id TEXT NOT NULL,
        borrower_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'reserved',
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        total_price REAL NOT NULL,
        deposit_amount REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (equipment_id) REFERENCES equipment(id),
        FOREIGN KEY (borrower_id) REFERENCES users(id)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS friendships (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        friend_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        tag TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (friend_id) REFERENCES users(id)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS access_codes (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        granter_id TEXT NOT NULL,
        recipient_id TEXT,
        code TEXT NOT NULL,
        access_type TEXT NOT NULL,
        instructions TEXT,
        expires_at TEXT NOT NULL,
        used INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS check_in_logs (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        is_check_in INTEGER NOT NULL,
        lat REAL, lng REAL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        order_id TEXT,
        reservation_id TEXT,
        payer_id TEXT NOT NULL,
        payee_id TEXT NOT NULL,
        amount REAL NOT NULL,
        deposit_amount REAL,
        commission_amount REAL,
        status TEXT NOT NULL DEFAULT 'pending',
        external_payment_id TEXT,
        provider TEXT,
        dispute_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS disputes (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        order_id TEXT,
        reservation_id TEXT,
        payment_id TEXT,
        reporter_id TEXT NOT NULL,
        respondent_id TEXT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'open',
        admin_notes TEXT,
        resolution TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS service_offers (
        id TEXT PRIMARY KEY,
        provider_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        service_type TEXT NOT NULL,
        price_from REAL,
        price_to REAL,
        location TEXT,
        lat REAL, lng REAL,
        radius_km REAL,
        skills TEXT DEFAULT '[]',
        availability_schedule TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (provider_id) REFERENCES users(id)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS badges (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        required_points INTEGER NOT NULL DEFAULT 0,
        category TEXT
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS user_badges (
        user_id TEXT NOT NULL,
        badge_id TEXT NOT NULL,
        earned_at TEXT NOT NULL,
        PRIMARY KEY (user_id, badge_id)
      )
    ''');
  }

  void _addColumnIfNotExists(String table, String column, String definition) {
    final cols = _db.select('PRAGMA table_info($table)');
    final exists = cols.any((c) => c['name'] == column);
    if (!exists) {
      _db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
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
