import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/social_service.dart';

class SocialRoutes {
  final SocialService socialService;

  SocialRoutes(this.socialService);

  Router get router {
    final router = Router();

    router.get('/friends/', _listFriends);
    router.post('/friends/', _sendFriendRequest);
    router.put('/friends/<id>/accept', _acceptFriendRequest);
    router.delete('/friends/<id>', _removeFriend);
    router.get('/badges/', _listBadges);
    router.get('/badges/mine', _getUserBadges);
    router.post('/access-codes/', _createAccessCode);
    router.get('/access-codes/<orderId>', _getAccessCodes);
    router.post('/check-in/', _logCheckIn);

    return router;
  }

  Future<Response> _listFriends(Request request) async {
    final userId = request.context['userId'] as String;
    final friends = socialService.listFriends(userId);
    return Response.ok(jsonEncode(friends),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _sendFriendRequest(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final friendId = body['friendId'] as String?;
      if (friendId == null) {
        return Response(400,
            body: jsonEncode({'error': 'friendId jest wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      final friendship = socialService.sendFriendRequest(
        userId: userId,
        friendId: friendId,
        tag: body['tag'] as String?,
      );
      return Response(201,
          body: jsonEncode(friendship),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _acceptFriendRequest(Request request, String id) async {
    final friendship = socialService.acceptFriendRequest(id);
    if (friendship == null) {
      return Response(404,
          body: jsonEncode({'error': 'Zaproszenie nie znalezione'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(friendship),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _removeFriend(Request request, String id) async {
    socialService.removeFriend(id);
    return Response.ok(jsonEncode({'deleted': true}),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _listBadges(Request request) async {
    final badges = socialService.listBadges();
    return Response.ok(jsonEncode(badges),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _getUserBadges(Request request) async {
    final userId = request.context['userId'] as String;
    final badges = socialService.getUserBadges(userId);
    return Response.ok(jsonEncode(badges),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _createAccessCode(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final orderId = body['orderId'] as String?;
      final accessType = body['accessType'] as String?;
      final expiresAt = body['expiresAt'] as String?;
      if (orderId == null || accessType == null || expiresAt == null) {
        return Response(400,
            body: jsonEncode({'error': 'orderId, accessType i expiresAt są wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      final code = socialService.createAccessCode(
        orderId: orderId,
        granterId: userId,
        recipientId: body['recipientId'] as String?,
        accessType: accessType,
        instructions: body['instructions'] as String?,
        expiresAt: expiresAt,
      );
      return Response(201,
          body: jsonEncode(code),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _getAccessCodes(Request request, String orderId) async {
    final codes = socialService.listAccessCodes(orderId);
    return Response.ok(jsonEncode(codes),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _logCheckIn(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final orderId = body['orderId'] as String?;
      final isCheckIn = body['isCheckIn'] as bool?;
      if (orderId == null || isCheckIn == null) {
        return Response(400,
            body: jsonEncode({'error': 'orderId i isCheckIn są wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      final log = socialService.logCheckIn(
        orderId: orderId,
        userId: userId,
        isCheckIn: isCheckIn,
        lat: (body['lat'] as num?)?.toDouble(),
        lng: (body['lng'] as num?)?.toDouble(),
      );
      return Response(201,
          body: jsonEncode(log),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }
}
