import 'package:uuid/uuid.dart';
import '../database/database.dart';

const _uuid = Uuid();

class PaymentService {
  final AppDatabase database;

  PaymentService(this.database);

  // --- Payments ---

  Map<String, dynamic> createPayment({
    String? orderId,
    String? reservationId,
    required String payerId,
    required String payeeId,
    required double amount,
    double? depositAmount,
    double? commissionAmount,
    String? provider,
  }) {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    database.db.execute(
      '''INSERT INTO payments (id, order_id, reservation_id, payer_id, payee_id, amount,
         deposit_amount, commission_amount, status, provider, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id, orderId, reservationId, payerId, payeeId, amount,
        depositAmount, commissionAmount, 'pending', provider, now, now,
      ],
    );
    return getPayment(id)!;
  }

  Map<String, dynamic>? getPayment(String id) {
    final results = database.db.select('SELECT * FROM payments WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return _rowToPayment(results.first);
  }

  List<Map<String, dynamic>> listPayments({
    String? payerId,
    String? payeeId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) {
    var query = 'SELECT * FROM payments';
    final conditions = <String>[];
    final params = <Object?>[];

    if (payerId != null) {
      conditions.add('payer_id = ?');
      params.add(payerId);
    }
    if (payeeId != null) {
      conditions.add('payee_id = ?');
      params.add(payeeId);
    }
    if (status != null) {
      conditions.add('status = ?');
      params.add(status);
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.addAll([limit, offset]);

    return database.db.select(query, params).map((row) => _rowToPayment(row)).toList();
  }

  Map<String, dynamic>? blockPayment(String id) {
    return _updatePaymentStatus(id, 'blocked');
  }

  Map<String, dynamic>? releasePayment(String id) {
    return _updatePaymentStatus(id, 'released');
  }

  Map<String, dynamic>? refundPayment(String id) {
    return _updatePaymentStatus(id, 'refunded');
  }

  Map<String, dynamic>? _updatePaymentStatus(String id, String status) {
    final now = DateTime.now().toIso8601String();
    database.db.execute(
      'UPDATE payments SET status = ?, updated_at = ? WHERE id = ?',
      [status, now, id],
    );
    return getPayment(id);
  }

  // --- Disputes ---

  Map<String, dynamic> createDispute({
    required String type,
    String? orderId,
    String? reservationId,
    String? paymentId,
    required String reporterId,
    String? respondentId,
    required String title,
    required String description,
  }) {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    database.db.execute(
      '''INSERT INTO disputes (id, type, order_id, reservation_id, payment_id, reporter_id,
         respondent_id, title, description, status, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id, type, orderId, reservationId, paymentId, reporterId,
        respondentId, title, description, 'open', now, now,
      ],
    );

    if (paymentId != null) {
      database.db.execute(
        'UPDATE payments SET dispute_id = ?, status = ?, updated_at = ? WHERE id = ?',
        [id, 'disputed', now, paymentId],
      );
    }

    return getDispute(id)!;
  }

  Map<String, dynamic>? getDispute(String id) {
    final results = database.db.select('SELECT * FROM disputes WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return _rowToDispute(results.first);
  }

  List<Map<String, dynamic>> listDisputes({
    String? reporterId,
    String? respondentId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) {
    var query = 'SELECT * FROM disputes';
    final conditions = <String>[];
    final params = <Object?>[];

    if (reporterId != null) {
      conditions.add('reporter_id = ?');
      params.add(reporterId);
    }
    if (respondentId != null) {
      conditions.add('respondent_id = ?');
      params.add(respondentId);
    }
    if (status != null) {
      conditions.add('status = ?');
      params.add(status);
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.addAll([limit, offset]);

    return database.db.select(query, params).map((row) => _rowToDispute(row)).toList();
  }

  Map<String, dynamic>? updateDisputeStatus(String id, String status, {String? adminNotes}) {
    final now = DateTime.now().toIso8601String();
    if (adminNotes != null) {
      database.db.execute(
        'UPDATE disputes SET status = ?, admin_notes = ?, updated_at = ? WHERE id = ?',
        [status, adminNotes, now, id],
      );
    } else {
      database.db.execute(
        'UPDATE disputes SET status = ?, updated_at = ? WHERE id = ?',
        [status, now, id],
      );
    }
    return getDispute(id);
  }

  Map<String, dynamic>? resolveDispute(String id, String resolution) {
    final now = DateTime.now().toIso8601String();
    database.db.execute(
      "UPDATE disputes SET status = 'resolved', resolution = ?, updated_at = ? WHERE id = ?",
      [resolution, now, id],
    );
    return getDispute(id);
  }

  Map<String, dynamic> _rowToPayment(Map<String, dynamic> row) => {
        'id': row['id'],
        'orderId': row['order_id'],
        'reservationId': row['reservation_id'],
        'payerId': row['payer_id'],
        'payeeId': row['payee_id'],
        'amount': row['amount'],
        'depositAmount': row['deposit_amount'],
        'commissionAmount': row['commission_amount'],
        'status': row['status'],
        'externalPaymentId': row['external_payment_id'],
        'provider': row['provider'],
        'disputeId': row['dispute_id'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      };

  Map<String, dynamic> _rowToDispute(Map<String, dynamic> row) => {
        'id': row['id'],
        'type': row['type'],
        'orderId': row['order_id'],
        'reservationId': row['reservation_id'],
        'paymentId': row['payment_id'],
        'reporterId': row['reporter_id'],
        'respondentId': row['respondent_id'],
        'title': row['title'],
        'description': row['description'],
        'status': row['status'],
        'adminNotes': row['admin_notes'],
        'resolution': row['resolution'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      };
}
