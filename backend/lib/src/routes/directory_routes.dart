import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/directory_service.dart';

class DirectoryRoutes {
  final DirectoryService directoryService;

  DirectoryRoutes(this.directoryService);

  Router get router {
    final router = Router();

    router.get('/', _listOffers);
    router.post('/', _createOffer);
    router.get('/<id>', _getOffer);
    router.put('/<id>', _updateOffer);
    router.delete('/<id>', _deactivateOffer);

    return router;
  }

  Future<Response> _listOffers(Request request) async {
    final type = request.url.queryParameters['type'];
    final query = request.url.queryParameters['query'];
    final latStr = request.url.queryParameters['lat'];
    final lngStr = request.url.queryParameters['lng'];
    final radiusStr = request.url.queryParameters['radius'];

    if (query != null || (latStr != null && lngStr != null)) {
      final offers = directoryService.searchOffers(
        query: query,
        type: type,
        lat: latStr != null ? double.tryParse(latStr) : null,
        lng: lngStr != null ? double.tryParse(lngStr) : null,
        radiusKm: radiusStr != null ? double.tryParse(radiusStr) : null,
      );
      return Response.ok(jsonEncode(offers),
          headers: {'content-type': 'application/json'});
    }

    final offers = directoryService.listOffers(type: type);
    return Response.ok(jsonEncode(offers),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _createOffer(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final title = body['title'] as String?;
      final serviceType = body['serviceType'] as String?;
      if (title == null || serviceType == null) {
        return Response(400,
            body: jsonEncode({'error': 'Tytuł i typ usługi są wymagane'}),
            headers: {'content-type': 'application/json'});
      }

      final offer = directoryService.createOffer(
        providerId: userId,
        title: title,
        description: body['description'] as String? ?? '',
        serviceType: serviceType,
        priceFrom: (body['priceFrom'] as num?)?.toDouble(),
        priceTo: (body['priceTo'] as num?)?.toDouble(),
        location: body['location'] as String?,
        lat: (body['lat'] as num?)?.toDouble(),
        lng: (body['lng'] as num?)?.toDouble(),
        radiusKm: (body['radiusKm'] as num?)?.toDouble(),
        skills: (body['skills'] as List<dynamic>?)?.cast<String>() ?? [],
        availabilitySchedule: body['availabilitySchedule'] as String?,
      );

      return Response(201,
          body: jsonEncode(offer),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _getOffer(Request request, String id) async {
    final offer = directoryService.getOffer(id);
    if (offer == null) {
      return Response(404,
          body: jsonEncode({'error': 'Oferta nie znaleziona'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(offer),
        headers: {'content-type': 'application/json'});
  }

  Future<Response> _updateOffer(Request request, String id) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final offer = directoryService.updateOffer(id, body);
      if (offer == null) {
        return Response(404,
            body: jsonEncode({'error': 'Oferta nie znaleziona'}),
            headers: {'content-type': 'application/json'});
      }
      return Response.ok(jsonEncode(offer),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(400,
          body: jsonEncode({'error': 'Nieprawidłowe dane: $e'}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _deactivateOffer(Request request, String id) async {
    final offer = directoryService.deactivateOffer(id);
    if (offer == null) {
      return Response(404,
          body: jsonEncode({'error': 'Oferta nie znaleziona'}),
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode(offer),
        headers: {'content-type': 'application/json'});
  }
}
