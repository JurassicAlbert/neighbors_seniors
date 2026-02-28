import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/review_service.dart';

class ReviewRoutes {
  final ReviewService reviewService;

  ReviewRoutes(this.reviewService);

  Router get router {
    final router = Router();

    router.post('/', _createReview);
    router.get('/user/<userId>', _getReviewsForUser);
    router.get('/order/<orderId>', _getReviewsForOrder);

    return router;
  }

  Future<Response> _createReview(Request request) async {
    try {
      final reviewerId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final orderId = body['orderId'] as String?;
      final revieweeId = body['revieweeId'] as String?;
      final rating = body['rating'] as int?;

      if (orderId == null || revieweeId == null || rating == null) {
        return Response(400,
            body: jsonEncode({'error': 'orderId, revieweeId i rating są wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      if (rating < 1 || rating > 5) {
        return Response(400,
            body: jsonEncode({'error': 'Ocena musi być od 1 do 5'}),
            headers: {'content-type': 'application/json'});
      }

      final review = reviewService.createReview(
        orderId: orderId,
        reviewerId: reviewerId,
        revieweeId: revieweeId,
        rating: rating,
        comment: body['comment'] as String?,
      );

      return Response(201,
          body: jsonEncode(review),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _getReviewsForUser(Request request, String userId) async {
    final reviews = reviewService.getReviewsForUser(userId);
    final avg = reviewService.getAverageRating(userId);
    return Response.ok(
      jsonEncode({'reviews': reviews, 'averageRating': avg}),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _getReviewsForOrder(Request request, String orderId) async {
    final reviews = reviewService.getReviewsForOrder(orderId);
    return Response.ok(jsonEncode(reviews),
        headers: {'content-type': 'application/json'});
  }
}
