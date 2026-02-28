import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/payment_service.dart';

class PaymentRoutes {
  final PaymentService paymentService;

  PaymentRoutes(this.paymentService);

  Router get router {
    final router = Router();

    router.post('/', _createPayment);
    router.get('/', _listPayments);
    router.get('/disputes/', _listDisputes);
    router.post('/disputes/', _createDispute);
    router.get('/disputes/<id>', _getDispute);
    router.get('/<id>', _getPayment);
    router.put('/<id>/release', _releasePayment);
    router.put('/<id>/refund', _refundPayment);

    return router;
  }

  Future<Response> _createPayment(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final payeeId = body['payeeId'] as String?;
      final amount = (body['amount'] as num?)?.toDouble();
      if (payeeId == null || amount == null) {
        return Response(400,
            body: jsonEncode({'error': 'payeeId i amount są wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      final payment = paymentService.createPayment(
        orderId: body['orderId'] as String?,
        reservationId: body['reservationId'] as String?,
        payerId: userId,
        payeeId: payeeId,
        amount: amount,
        depositAmount: (body['depositAmount'] as num?)?.toDouble(),
        commissionAmount: (body['commissionAmount'] as num?)?.toDouble(),
        provider: body['provider'] as String?,
      );

      return Response(201,
          body: jsonEncode(payment),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _listPayments(Request request) async {
    final userId = request.context['userId'] as String;
    final payments = paymentService.listPayments(payerId: userId);
    final received = paymentService.listPayments(payeeId: userId);
    return Response.ok(
      jsonEncode({'sent': payments, 'received': received}),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _getPayment(Request request, String id) async {
    final payment = paymentService.getPayment(id);
    if (payment == null) {
      return Response(404,
          body: jsonEncode({'error': 'Płatność nie znaleziona'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(payment),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _releasePayment(Request request, String id) async {
    final payment = paymentService.releasePayment(id);
    if (payment == null) {
      return Response(404,
          body: jsonEncode({'error': 'Płatność nie znaleziona'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(payment),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _refundPayment(Request request, String id) async {
    final payment = paymentService.refundPayment(id);
    if (payment == null) {
      return Response(404,
          body: jsonEncode({'error': 'Płatność nie znaleziona'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(payment),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _createDispute(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final type = body['type'] as String?;
      final title = body['title'] as String?;
      final description = body['description'] as String?;
      if (type == null || title == null || description == null) {
        return Response(400,
            body: jsonEncode({'error': 'type, title i description są wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      final dispute = paymentService.createDispute(
        type: type,
        orderId: body['orderId'] as String?,
        reservationId: body['reservationId'] as String?,
        paymentId: body['paymentId'] as String?,
        reporterId: userId,
        respondentId: body['respondentId'] as String?,
        title: title,
        description: description,
      );

      return Response(201,
          body: jsonEncode(dispute),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _listDisputes(Request request) async {
    final userId = request.context['userId'] as String;
    final role = request.context['role'] as String;

    List<Map<String, dynamic>> disputes;
    if (role == 'admin') {
      disputes = paymentService.listDisputes();
    } else {
      disputes = paymentService.listDisputes(reporterId: userId);
    }
    return Response.ok(jsonEncode(disputes),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _getDispute(Request request, String id) async {
    final dispute = paymentService.getDispute(id);
    if (dispute == null) {
      return Response(404,
          body: jsonEncode({'error': 'Spór nie znaleziony'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(dispute),
        headers: {'content-type': 'application/json'});
  }
}
