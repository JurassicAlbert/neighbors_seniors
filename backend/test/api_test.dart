import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

const baseUrl = 'http://localhost:8080';

void main() {
  late String familyToken;
  late String workerToken;
  late String adminToken;
  late String orderId;

  setUpAll(() async {
    await Future.delayed(const Duration(seconds: 1));
  });

  group('Auth', () {
    test('POST /api/auth/register creates a new user', () async {
      final uniqueEmail = 'testuser_${DateTime.now().millisecondsSinceEpoch}@test.pl';
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': uniqueEmail,
          'password': 'haslo1234',
          'name': 'Test User',
          'phone': '+48444444444',
          'role': 'family',
        }),
      );
      expect(res.statusCode, 201);
      final data = jsonDecode(res.body);
      expect(data['token'], isNotNull);
      expect(data['user']['name'], 'Test User');
    });

    test('POST /api/auth/register rejects duplicate email', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'admin@sasiedzi.pl',
          'password': 'haslo1234',
          'name': 'Test Duplicate',
          'role': 'family',
        }),
      );
      expect(res.statusCode, 409);
    });

    test('POST /api/auth/login succeeds with correct credentials', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'rodzina@test.pl',
          'password': 'test1234',
        }),
      );
      expect(res.statusCode, 200);
      final data = jsonDecode(res.body);
      familyToken = data['token'] as String;
      expect(familyToken, isNotEmpty);
    });

    test('login as worker', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'wykonawca@test.pl',
          'password': 'test1234',
        }),
      );
      expect(res.statusCode, 200);
      workerToken = jsonDecode(res.body)['token'] as String;
    });

    test('login as admin', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'admin@sasiedzi.pl',
          'password': 'admin1234',
        }),
      );
      expect(res.statusCode, 200);
      adminToken = jsonDecode(res.body)['token'] as String;
    });

    test('POST /api/auth/login fails with wrong password', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': 'rodzina@test.pl',
          'password': 'wrongpassword',
        }),
      );
      expect(res.statusCode, 401);
    });
  });

  group('Users', () {
    test('GET /api/users/me returns current user', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: {'authorization': 'Bearer $familyToken'},
      );
      expect(res.statusCode, 200);
      final data = jsonDecode(res.body);
      expect(data['email'], 'rodzina@test.pl');
      expect(data['role'], 'family');
    });

    test('GET /api/users/me returns 401 without token', () async {
      final res = await http.get(Uri.parse('$baseUrl/api/users/me'));
      expect(res.statusCode, 401);
    });
  });

  group('Orders', () {
    test('POST /api/orders/ creates an order', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/api/orders/'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $familyToken',
        },
        body: jsonEncode({
          'type': 'shopping',
          'title': 'Test zakupy',
          'description': 'Zakupy testowe',
          'price': 45.0,
          'address': 'ul. Testowa 1',
        }),
      );
      expect(res.statusCode, 201);
      final data = jsonDecode(res.body);
      orderId = data['id'] as String;
      expect(data['title'], 'Test zakupy');
      expect(data['status'], 'pending');
      expect(data['commission'], 4.5);
    });

    test('GET /api/orders/ returns user orders', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/api/orders/'),
        headers: {'authorization': 'Bearer $familyToken'},
      );
      expect(res.statusCode, 200);
      final data = jsonDecode(res.body) as List;
      expect(data, isNotEmpty);
    });

    test('GET /api/orders/available returns pending orders', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/api/orders/available'),
        headers: {'authorization': 'Bearer $workerToken'},
      );
      expect(res.statusCode, 200);
      final data = jsonDecode(res.body) as List;
      expect(data, isNotEmpty);
    });

    test('PUT /api/orders/:id/accept assigns worker', () async {
      final res = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId/accept'),
        headers: {'authorization': 'Bearer $workerToken'},
      );
      expect(res.statusCode, 200);
      final data = jsonDecode(res.body);
      expect(data['status'], 'accepted');
      expect(data['workerId'], isNotNull);
    });

    test('PUT /api/orders/:id/complete marks order done', () async {
      final res = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId/complete'),
        headers: {'authorization': 'Bearer $workerToken'},
      );
      expect(res.statusCode, 200);
      expect(jsonDecode(res.body)['status'], 'completed');
    });
  });

  group('Reviews', () {
    test('POST /api/reviews/ creates a review', () async {
      final meRes = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: {'authorization': 'Bearer $workerToken'},
      );
      final workerId = jsonDecode(meRes.body)['id'] as String;

      final res = await http.post(
        Uri.parse('$baseUrl/api/reviews/'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $familyToken',
        },
        body: jsonEncode({
          'orderId': orderId,
          'revieweeId': workerId,
          'rating': 5,
          'comment': 'Doskonała obsługa!',
        }),
      );
      expect(res.statusCode, 201);
      expect(jsonDecode(res.body)['rating'], 5);
    });
  });

  group('Admin', () {
    test('GET /api/admin/stats returns platform stats', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/api/admin/stats'),
        headers: {'authorization': 'Bearer $adminToken'},
      );
      expect(res.statusCode, 200);
      final data = jsonDecode(res.body);
      expect(data['totalUsers'], greaterThan(0));
      expect(data['totalOrders'], greaterThan(0));
    });

    test('GET /api/admin/users returns all users', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/api/admin/users'),
        headers: {'authorization': 'Bearer $adminToken'},
      );
      expect(res.statusCode, 200);
      final data = jsonDecode(res.body) as List;
      expect(data.length, greaterThan(3));
    });

    test('GET /api/admin/stats rejected for non-admin', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/api/admin/stats'),
        headers: {'authorization': 'Bearer $familyToken'},
      );
      expect(res.statusCode, 403);
    });
  });
}
