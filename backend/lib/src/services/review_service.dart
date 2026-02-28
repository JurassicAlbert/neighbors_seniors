import 'package:uuid/uuid.dart';
import '../database/database.dart';

const _uuid = Uuid();

class ReviewService {
  final AppDatabase database;

  ReviewService(this.database);

  Map<String, dynamic> createReview({
    required String orderId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    String? comment,
  }) {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    database.db.execute(
      'INSERT INTO reviews (id, order_id, reviewer_id, reviewee_id, rating, comment, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, orderId, reviewerId, revieweeId, rating, comment, now],
    );

    return getReview(id)!;
  }

  Map<String, dynamic>? getReview(String id) {
    final results = database.db.select('''
      SELECT r.*, u.name as reviewer_name, u.email as reviewer_email
      FROM reviews r LEFT JOIN users u ON r.reviewer_id = u.id
      WHERE r.id = ?
    ''', [id]);
    if (results.isEmpty) return null;
    return _rowToReview(results.first);
  }

  List<Map<String, dynamic>> getReviewsForUser(String userId) {
    return database.db.select('''
      SELECT r.*, u.name as reviewer_name, u.email as reviewer_email
      FROM reviews r LEFT JOIN users u ON r.reviewer_id = u.id
      WHERE r.reviewee_id = ?
      ORDER BY r.created_at DESC
    ''', [userId]).map((row) => _rowToReview(row)).toList();
  }

  List<Map<String, dynamic>> getReviewsForOrder(String orderId) {
    return database.db.select('''
      SELECT r.*, u.name as reviewer_name, u.email as reviewer_email
      FROM reviews r LEFT JOIN users u ON r.reviewer_id = u.id
      WHERE r.order_id = ?
      ORDER BY r.created_at DESC
    ''', [orderId]).map((row) => _rowToReview(row)).toList();
  }

  double? getAverageRating(String userId) {
    final results = database.db.select(
      'SELECT AVG(rating) as avg_rating FROM reviews WHERE reviewee_id = ?',
      [userId],
    );
    if (results.isEmpty) return null;
    return (results.first['avg_rating'] as num?)?.toDouble();
  }

  Map<String, dynamic> _rowToReview(Map<String, dynamic> row) {
    final review = <String, dynamic>{
      'id': row['id'],
      'orderId': row['order_id'],
      'reviewerId': row['reviewer_id'],
      'revieweeId': row['reviewee_id'],
      'rating': row['rating'],
      'comment': row['comment'],
      'createdAt': row['created_at'],
    };
    if (row['reviewer_name'] != null) {
      review['reviewer'] = {
        'id': row['reviewer_id'],
        'name': row['reviewer_name'],
        'email': row['reviewer_email'],
      };
    }
    return review;
  }
}
