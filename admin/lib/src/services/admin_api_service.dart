import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neighbors_seniors_shared/shared.dart';

class AdminApiService {
  static String baseUrl = 'http://localhost:8080';
  String? _token;

  bool get isAuthenticated => _token != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<AuthResponse> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Błąd logowania');
    }
    final data = AuthResponse.fromJson(jsonDecode(res.body));
    if (data.user.role != UserRole.admin) {
      throw Exception('Brak uprawnień administratora');
    }
    _token = data.token;
    return data;
  }

  void logout() => _token = null;

  Future<StatsModel> getStats() async {
    final res = await http.get(Uri.parse('$baseUrl/api/admin/stats'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Błąd pobierania statystyk');
    return StatsModel.fromJson(jsonDecode(res.body));
  }

  Future<List<UserModel>> getUsers({String? role}) async {
    var url = '$baseUrl/api/admin/users';
    if (role != null) url += '?role=$role';
    final res = await http.get(Uri.parse(url), headers: _headers);
    if (res.statusCode != 200) throw Exception('Błąd pobierania użytkowników');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OrderModel>> getOrders({String? status}) async {
    var url = '$baseUrl/api/admin/orders';
    if (status != null) url += '?status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);
    if (res.statusCode != 200) throw Exception('Błąd pobierania zleceń');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserModel>> getPendingVerifications() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/verifications'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Błąd pobierania weryfikacji');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> verifyWorker(String id) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/users/$id/verify'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Błąd weryfikacji');
    return UserModel.fromJson(jsonDecode(res.body));
  }

  Future<UserModel> rejectWorker(String id) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/users/$id/reject'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Błąd odrzucenia');
    return UserModel.fromJson(jsonDecode(res.body));
  }
}
