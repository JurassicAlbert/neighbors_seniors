import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/user_service.dart';

class UserRoutes {
  final UserService userService;

  UserRoutes(this.userService);

  Router get router {
    final router = Router();

    router.get('/me', _getMe);
    router.put('/me', _updateMe);
    router.get('/<id>', _getUser);

    return router;
  }

  Future<Response> _getMe(Request request) async {
    final userId = request.context['userId'] as String;
    final user = userService.getUser(userId);
    if (user == null) {
      return Response(404,
          body: jsonEncode({'error': 'Użytkownik nie znaleziony'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(user),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _updateMe(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final user = userService.updateUser(userId, body);
      if (user == null) {
        return Response(404,
            body: jsonEncode({'error': 'Użytkownik nie znaleziony'}),
            headers: {'content-type': 'application/json'});
      }
      return Response.ok(jsonEncode(user),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _getUser(Request request, String id) async {
    final user = userService.getUser(id);
    if (user == null) {
      return Response(404,
          body: jsonEncode({'error': 'Użytkownik nie znaleziony'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(user),
        headers: {'content-type': 'application/json'});
  }
}
