import 'package:shelf/shelf.dart';
import '../services/auth_service.dart';

Middleware authMiddleware(AuthService authService) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401,
            body: '{"error": "Brak tokenu autoryzacji"}',
            headers: {'content-type': 'application/json'});
      }

      final token = authHeader.substring(7);
      final payload = authService.verifyToken(token);
      if (payload == null) {
        return Response(401,
            body: '{"error": "Nieprawidłowy token"}',
            headers: {'content-type': 'application/json'});
      }

      final updatedRequest = request.change(context: {
        'userId': payload['userId'] as String,
        'role': payload['role'] as String,
      });

      return innerHandler(updatedRequest);
    };
  };
}

Middleware adminMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final role = request.context['role'] as String?;
      if (role != 'admin') {
        return Response(403,
            body: '{"error": "Brak uprawnień administratora"}',
            headers: {'content-type': 'application/json'});
      }
      return innerHandler(request);
    };
  };
}
