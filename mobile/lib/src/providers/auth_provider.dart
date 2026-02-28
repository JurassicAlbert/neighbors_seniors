import 'package:flutter/material.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api;
  UserModel? _user;
  bool _loading = false;
  String? _error;

  AuthProvider(this.api);

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> tryAutoLogin() async {
    await api.init();
    if (!api.isAuthenticated) return false;
    try {
      _user = await api.getMe();
      notifyListeners();
      return true;
    } catch (_) {
      await api.clearToken();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await api.login(email: email, password: password);
      _user = result.user;
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Błąd połączenia z serwerem';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await api.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
      _user = result.user;
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Błąd połączenia z serwerem';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await api.clearToken();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
