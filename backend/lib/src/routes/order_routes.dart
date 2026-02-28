import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/order_service.dart';

class OrderRoutes {
  final OrderService orderService;

  OrderRoutes(this.orderService);

  Router get router {
    final router = Router();

    router.get('/', _getOrders);
    router.get('/available', _getAvailableOrders);
    router.post('/', _createOrder);
    router.get('/<id>', _getOrder);
    router.put('/<id>/accept', _acceptOrder);
    router.put('/<id>/start', _startOrder);
    router.put('/<id>/complete', _completeOrder);
    router.put('/<id>/cancel', _cancelOrder);

    return router;
  }

  Future<Response> _getOrders(Request request) async {
    final userId = request.context['userId'] as String;
    final role = request.context['role'] as String;

    List<Map<String, dynamic>> orders;
    if (role == 'worker') {
      orders = orderService.getOrders(workerId: userId);
    } else if (role == 'admin') {
      orders = orderService.getOrders();
    } else {
      orders = orderService.getOrders(requesterId: userId);
    }

    return Response.ok(jsonEncode(orders),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _getAvailableOrders(Request request) async {
    final orders = orderService.getAvailableOrders();
    return Response.ok(jsonEncode(orders),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _createOrder(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final type = body['type'] as String?;
      final title = body['title'] as String?;
      if (type == null || title == null) {
        return Response(400,
            body: jsonEncode({'error': 'Typ i tytuł zlecenia są wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      final order = orderService.createOrder(
        type: type,
        title: title,
        description: body['description'] as String? ?? '',
        requesterId: userId,
        seniorId: body['seniorId'] as String?,
        price: (body['price'] as num?)?.toDouble(),
        deposit: (body['deposit'] as num?)?.toDouble(),
        address: body['address'] as String? ?? '',
        lat: (body['lat'] as num?)?.toDouble(),
        lng: (body['lng'] as num?)?.toDouble(),
        scheduledAt: body['scheduledAt'] as String?,
      );

      return Response(201,
          body: jsonEncode(order),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _getOrder(Request request, String id) async {
    final order = orderService.getOrder(id);
    if (order == null) {
      return Response(404,
          body: jsonEncode({'error': 'Zlecenie nie znalezione'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(order),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _acceptOrder(Request request, String id) async {
    final workerId = request.context['userId'] as String;
    final order = orderService.updateOrderStatus(id, 'accepted', workerId: workerId);
    if (order == null) {
      return Response(404,
          body: jsonEncode({'error': 'Zlecenie nie znalezione'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(order),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _startOrder(Request request, String id) async {
    final order = orderService.updateOrderStatus(id, 'inProgress');
    if (order == null) {
      return Response(404,
          body: jsonEncode({'error': 'Zlecenie nie znalezione'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(order),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _completeOrder(Request request, String id) async {
    final order = orderService.updateOrderStatus(id, 'completed');
    if (order == null) {
      return Response(404,
          body: jsonEncode({'error': 'Zlecenie nie znalezione'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(order),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _cancelOrder(Request request, String id) async {
    final order = orderService.updateOrderStatus(id, 'cancelled');
    if (order == null) {
      return Response(404,
          body: jsonEncode({'error': 'Zlecenie nie znalezione'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(order),
        headers: {'content-type': 'application/json'});
  }
}
