import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';

class AuthRoutes {
  final AuthService authService;

  AuthRoutes(this.authService);

  Router get router {
    final router = Router();

    router.post('/register', _register);
    router.post('/login', _login);

    return router;
  }

  Future<Response> _register(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final email = body['email'] as String?;
      final password = body['password'] as String?;
      final name = body['name'] as String?;
      final phone = body['phone'] as String? ?? '';
      final role = body['role'] as String? ?? 'senior';

      if (email == null || password == null || name == null) {
        return Response(400,
            body: jsonEncode({'error': 'Email, hasło i imię są wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      if (password.length < 8) {
        return Response(400,
            body: jsonEncode({'error': 'Hasło musi mieć co najmniej 8 znaków'}),
            headers: {'content-type': 'application/json'});
      }

      final result = authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );

      if (result == null) {
        return Response(409,
            body: jsonEncode({'error': 'Użytkownik z tym adresem email już istnieje'}),
            headers: {'content-type': 'application/json'});
      }

      return Response(201,
          body: jsonEncode(result),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final email = body['email'] as String?;
      final password = body['password'] as String?;

      if (email == null || password == null) {
        return Response(400,
            body: jsonEncode({'error': 'Email i hasło są wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      final result = authService.login(email: email, password: password);

      if (result == null) {
        return Response(401,
            body: jsonEncode({'error': 'Nieprawidłowy email lub hasło'}),
            headers: {'content-type': 'application/json'});
      }

      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }
}
