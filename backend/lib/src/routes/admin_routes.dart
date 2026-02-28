import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/user_service.dart';
import '../services/order_service.dart';
import '../services/stats_service.dart';
import '../services/equipment_service.dart';
import '../services/payment_service.dart';

class AdminRoutes {
  final UserService userService;
  final OrderService orderService;
  final StatsService statsService;
  final EquipmentService equipmentService;
  final PaymentService paymentService;

  AdminRoutes(this.userService, this.orderService, this.statsService,
      this.equipmentService, this.paymentService);

  Router get router {
    final router = Router();

    router.get('/stats', _getStats);
    router.get('/users', _getUsers);
    router.get('/orders', _getOrders);
    router.get('/verifications', _getPendingVerifications);
    router.put('/users/<id>/verify', _verifyWorker);
    router.put('/users/<id>/reject', _rejectWorker);
    router.get('/equipment', _getEquipment);
    router.get('/disputes', _getDisputes);
    router.put('/disputes/<id>/resolve', _resolveDispute);

    return router;
  }

  Future<Response> _getStats(Request request) async {
    final stats = statsService.getStats();
    return Response.ok(jsonEncode(stats),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _getUsers(Request request) async {
    final role = request.url.queryParameters['role'];
    final users = userService.getAllUsers(role: role);
    return Response.ok(jsonEncode(users),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _getOrders(Request request) async {
    final status = request.url.queryParameters['status'];
    final type = request.url.queryParameters['type'];
    final orders = orderService.getOrders(status: status, type: type);
    return Response.ok(jsonEncode(orders),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _getPendingVerifications(Request request) async {
    final verifications = userService.getPendingVerifications();
    return Response.ok(jsonEncode(verifications),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _verifyWorker(Request request, String id) async {
    final user = userService.updateUser(id, {'verificationStatus': 'verified'});
    if (user == null) {
      return Response(404,
          body: jsonEncode({'error': 'Użytkownik nie znaleziony'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(user),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _rejectWorker(Request request, String id) async {
    final user = userService.updateUser(id, {'verificationStatus': 'rejected'});
    if (user == null) {
      return Response(404,
          body: jsonEncode({'error': 'Użytkownik nie znaleziony'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(user),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _getEquipment(Request request) async {
    final category = request.url.queryParameters['category'];
    final status = request.url.queryParameters['status'];
    final items = equipmentService.listEquipment(
      category: category,
      status: status,
    );
    return Response.ok(jsonEncode(items),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _getDisputes(Request request) async {
    final status = request.url.queryParameters['status'];
    final disputes = paymentService.listDisputes(status: status);
    return Response.ok(jsonEncode(disputes),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _resolveDispute(Request request, String id) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final resolution = body['resolution'] as String?;
      if (resolution == null || resolution.trim().isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'Opis rozwiązania jest wymagany'}),
            headers: {'content-type': 'application/json'});
      }
      final dispute = paymentService.resolveDispute(id, resolution);
      if (dispute == null) {
        return Response(404,
            body: jsonEncode({'error': 'Spór nie znaleziony'}),
            headers: {'content-type': 'application/json'});
      }
      return Response.ok(jsonEncode(dispute),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }
}
