import 'package:flutter/material.dart';
import 'package:neighbors_seniors_shared/shared.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService api;
  List<OrderModel> _orders = [];
  List<OrderModel> _availableOrders = [];
  bool _loading = false;
  String? _error;

  OrderProvider(this.api);

  List<OrderModel> get orders => _orders;
  List<OrderModel> get availableOrders => _availableOrders;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadOrders() async {
    _loading = true;
    notifyListeners();
    try {
      _orders = await api.getOrders();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Błąd ładowania zleceń';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadAvailableOrders() async {
    _loading = true;
    notifyListeners();
    try {
      _availableOrders = await api.getAvailableOrders();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Błąd ładowania zleceń';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> createOrder(Map<String, dynamic> data) async {
    try {
      await api.createOrder(data);
      await loadOrders();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptOrder(String id) async {
    try {
      await api.acceptOrder(id);
      await loadOrders();
      await loadAvailableOrders();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeOrder(String id) async {
    try {
      await api.completeOrder(id);
      await loadOrders();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelOrder(String id) async {
    try {
      await api.cancelOrder(id);
      await loadOrders();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
