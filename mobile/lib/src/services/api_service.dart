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
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
