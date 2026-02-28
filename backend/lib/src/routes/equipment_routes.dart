import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/equipment_service.dart';

class EquipmentRoutes {
  final EquipmentService equipmentService;

  EquipmentRoutes(this.equipmentService);

  Router get router {
    final router = Router();

    router.get('/', _listEquipment);
    router.post('/', _createEquipment);
    router.get('/reservations/', _listReservations);
    router.get('/<id>', _getEquipment);
    router.put('/<id>', _updateEquipment);
    router.delete('/<id>', _deleteEquipment);
    router.post('/<id>/reserve', _createReservation);
    router.put('/reservations/<id>/status', _updateReservationStatus);

    return router;
  }

  Future<Response> _listEquipment(Request request) async {
    final category = request.url.queryParameters['category'];
    final status = request.url.queryParameters['status'];
    final ownerId = request.url.queryParameters['ownerId'];

    final items = equipmentService.listEquipment(
      category: category,
      status: status,
      ownerId: ownerId,
    );
    return Response.ok(jsonEncode(items),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _createEquipment(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final title = body['title'] as String?;
      final category = body['category'] as String?;
      if (title == null || category == null) {
        return Response(400,
            body: jsonEncode({'error': 'Tytuł i kategoria są wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      final item = equipmentService.createEquipment(
        ownerId: userId,
        title: title,
        description: body['description'] as String? ?? '',
        category: category,
        condition: body['condition'] as String? ?? 'good',
        photoUrls: (body['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [],
        pricePerUnit: (body['pricePerUnit'] as num?)?.toDouble() ?? 0,
        priceUnit: body['priceUnit'] as String? ?? 'day',
        depositAmount: (body['depositAmount'] as num?)?.toDouble(),
        location: body['location'] as String?,
        lat: (body['lat'] as num?)?.toDouble(),
        lng: (body['lng'] as num?)?.toDouble(),
        isRecurring: body['isRecurring'] as bool? ?? false,
        availabilitySchedule: body['availabilitySchedule'] as String?,
      );

      return Response(201,
          body: jsonEncode(item),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _getEquipment(Request request, String id) async {
    final item = equipmentService.getEquipment(id);
    if (item == null) {
      return Response(404,
          body: jsonEncode({'error': 'Sprzęt nie znaleziony'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(item),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _updateEquipment(Request request, String id) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final item = equipmentService.updateEquipment(id, body);
      if (item == null) {
        return Response(404,
            body: jsonEncode({'error': 'Sprzęt nie znaleziony'}),
            headers: {'content-type': 'application/json'});
      }
      return Response.ok(jsonEncode(item),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _deleteEquipment(Request request, String id) async {
    equipmentService.deleteEquipment(id);
    return Response.ok(jsonEncode({'deleted': true}),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _createReservation(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final equipment = equipmentService.getEquipment(id);
      if (equipment == null) {
        return Response(404,
            body: jsonEncode({'error': 'Sprzęt nie znaleziony'}),
            headers: {'content-type': 'application/json'});
      }

      final startDate = body['startDate'] as String?;
      final endDate = body['endDate'] as String?;
      final totalPrice = (body['totalPrice'] as num?)?.toDouble();
      if (startDate == null || endDate == null || totalPrice == null) {
        return Response(400,
            body: jsonEncode({'error': 'Daty i cena są wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      final reservation = equipmentService.createReservation(
        equipmentId: id,
        borrowerId: userId,
        ownerId: equipment['ownerId'] as String,
        startDate: startDate,
        endDate: endDate,
        totalPrice: totalPrice,
        depositAmount: (body['depositAmount'] as num?)?.toDouble(),
        notes: body['notes'] as String?,
      );

      return Response(201,
          body: jsonEncode(reservation),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _listReservations(Request request) async {
    final userId = request.context['userId'] as String;
    final reservations = equipmentService.listReservations(borrowerId: userId);
    return Response.ok(jsonEncode(reservations),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _updateReservationStatus(Request request, String id) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final status = body['status'] as String?;
      if (status == null) {
        return Response(400,
            body: jsonEncode({'error': 'Status jest wymagany'}),
            headers: {'content-type': 'application/json'});
      }

      final reservation = equipmentService.updateReservationStatus(id, status);
      if (reservation == null) {
        return Response(404,
            body: jsonEncode({'error': 'Rezerwacja nie znaleziona'}),
            headers: {'content-type': 'application/json'});
      }
      return Response.ok(jsonEncode(reservation),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }
}
