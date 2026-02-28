import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neighbors_seniors_shared/shared.dart';

const _envApiUrl = String.fromEnvironment('API_URL');

String _defaultBaseUrl() {
  if (_envApiUrl.isNotEmpty) return _envApiUrl;
  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

class ApiService {
  static String baseUrl = _defaultBaseUrl();
  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      baseUrl = savedUrl;
    }
    _token = prefs.getString('auth_token');
  }

  Future<void> setBaseUrl(String url) async {
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  bool get isAuthenticated => _token != null;

  // Auth
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'role': role.name,
      }),
    );
    if (res.statusCode != 201) {
      throw ApiException(jsonDecode(res.body)['error'] ?? 'Błąd rejestracji');
    }
    final data = AuthResponse.fromJson(jsonDecode(res.body));
    await _saveToken(data.token);
    return data;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw ApiException(jsonDecode(res.body)['error'] ?? 'Błąd logowania');
    }
    final data = AuthResponse.fromJson(jsonDecode(res.body));
    await _saveToken(data.token);
    return data;
  }

  // Users
  Future<UserModel> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/users/me'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać profilu');
    return UserModel.fromJson(jsonDecode(res.body));
  }

  Future<UserModel> updateMe(Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/users/me'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się zaktualizować profilu');
    return UserModel.fromJson(jsonDecode(res.body));
  }

  // Orders
  Future<List<OrderModel>> getOrders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/orders'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać zleceń');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OrderModel>> getAvailableOrders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/orders/available'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać zleceń');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OrderModel> createOrder(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) {
      throw ApiException(jsonDecode(res.body)['error'] ?? 'Nie udało się utworzyć zlecenia');
    }
    return OrderModel.fromJson(jsonDecode(res.body));
  }

  Future<OrderModel> acceptOrder(String id) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/orders/$id/accept'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się zaakceptować zlecenia');
    return OrderModel.fromJson(jsonDecode(res.body));
  }

  Future<OrderModel> startOrder(String id) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/orders/$id/start'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się rozpocząć zlecenia');
    return OrderModel.fromJson(jsonDecode(res.body));
  }

  Future<OrderModel> completeOrder(String id) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/orders/$id/complete'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się zakończyć zlecenia');
    return OrderModel.fromJson(jsonDecode(res.body));
  }

  Future<OrderModel> cancelOrder(String id) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/orders/$id/cancel'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się anulować zlecenia');
    return OrderModel.fromJson(jsonDecode(res.body));
  }

  // Reviews
  Future<ReviewModel> createReview(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/reviews'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) throw ApiException('Nie udało się dodać opinii');
    return ReviewModel.fromJson(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> getReviewsForUser(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/reviews/user/$userId'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać opinii');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── v2: Equipment ──

  Future<List<EquipmentModel>> listEquipment({String? category}) async {
    final uri = Uri.parse('$baseUrl/api/v2/equipment/').replace(
      queryParameters: {if (category != null) 'category': category},
    );
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać sprzętu');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => EquipmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EquipmentModel> createEquipment(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v2/equipment/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) {
      throw ApiException(jsonDecode(res.body)['error'] ?? 'Nie udało się dodać sprzętu');
    }
    return EquipmentModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<EquipmentModel> getEquipment(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/equipment/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać sprzętu');
    return EquipmentModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<EquipmentReservation> reserveEquipment(String equipmentId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v2/equipment/$equipmentId/reserve'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) {
      throw ApiException(jsonDecode(res.body)['error'] ?? 'Nie udało się zarezerwować');
    }
    return EquipmentReservation.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<EquipmentReservation>> listReservations() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/equipment/reservations/'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać rezerwacji');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => EquipmentReservation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EquipmentReservation> updateReservationStatus(String id, String status) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/v2/equipment/reservations/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się zaktualizować rezerwacji');
    return EquipmentReservation.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── v2: Friends / Social ──

  Future<List<FriendshipModel>> listFriends() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/social/friends/'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać znajomych');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => FriendshipModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FriendshipModel> sendFriendRequest(String friendId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v2/social/friends/'),
      headers: _headers,
      body: jsonEncode({'friendId': friendId}),
    );
    if (res.statusCode != 201) {
      throw ApiException(jsonDecode(res.body)['error'] ?? 'Nie udało się wysłać zaproszenia');
    }
    return FriendshipModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<FriendshipModel> acceptFriendRequest(String id) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/v2/social/friends/$id/accept'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się zaakceptować zaproszenia');
    return FriendshipModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> removeFriend(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/v2/social/friends/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się usunąć znajomego');
  }

  // ── v2: Badges ──

  Future<List<BadgeModel>> listBadges() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/social/badges/'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać odznak');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => BadgeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BadgeModel>> listMyBadges() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/social/badges/mine'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać moich odznak');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => BadgeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── v2: Directory ──

  Future<List<ServiceOffer>> searchDirectory({String? type, String? query}) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type;
    if (query != null) params['query'] = query;
    final uri = Uri.parse('$baseUrl/api/v2/directory/')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw ApiException('Nie udało się wyszukać ofert');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => ServiceOffer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ServiceOffer> createOffer(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v2/directory/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) {
      throw ApiException(jsonDecode(res.body)['error'] ?? 'Nie udało się utworzyć oferty');
    }
    return ServiceOffer.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── v2: Access Codes ──

  Future<AccessCodeModel> createAccessCode(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v2/social/access-codes/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) {
      throw ApiException(jsonDecode(res.body)['error'] ?? 'Nie udało się utworzyć kodu');
    }
    return AccessCodeModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<AccessCodeModel>> getAccessCodes(String orderId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/social/access-codes/$orderId'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać kodów');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => AccessCodeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── v2: Check-in ──

  Future<CheckInLog> checkIn(String orderId, {double? lat, double? lng}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v2/social/check-in/'),
      headers: _headers,
      body: jsonEncode({
        'orderId': orderId,
        'isCheckIn': true,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      }),
    );
    if (res.statusCode != 201) throw ApiException('Nie udało się zameldować');
    return CheckInLog.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<CheckInLog> checkOut(String orderId, {double? lat, double? lng}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v2/social/check-in/'),
      headers: _headers,
      body: jsonEncode({
        'orderId': orderId,
        'isCheckIn': false,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      }),
    );
    if (res.statusCode != 201) throw ApiException('Nie udało się wymeldować');
    return CheckInLog.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── v2: Notifications ──

  Future<List<NotificationModel>> getNotifications() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/notifications/'),
      headers: _headers,
    );
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── v2: Payments ──

  Future<PaymentModel> createPayment(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v2/payments/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) {
      throw ApiException(jsonDecode(res.body)['error'] ?? 'Nie udało się utworzyć płatności');
    }
    return PaymentModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<PaymentModel>> listPayments() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/payments/'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać płatności');
    final decoded = jsonDecode(res.body);
    if (decoded is List) {
      return decoded.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    final map = decoded as Map<String, dynamic>;
    final sent = (map['sent'] as List?) ?? [];
    final received = (map['received'] as List?) ?? [];
    return [
      ...sent.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)),
      ...received.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)),
    ];
  }

  // ── v2: Disputes ──

  Future<DisputeModel> createDispute(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v2/payments/disputes/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) {
      throw ApiException(jsonDecode(res.body)['error'] ?? 'Nie udało się zgłosić sporu');
    }
    return DisputeModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<DisputeModel>> listDisputes() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v2/payments/disputes/'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException('Nie udało się pobrać sporów');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => DisputeModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
