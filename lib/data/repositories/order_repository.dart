import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/data/mock/mock_order_data.dart';
import 'package:campus_eats_ag/models/order.dart';
import 'package:campus_eats_ag/models/order_item.dart';

class OrderRepository {
  static const String _key = 'orders_data';
  final List<Order> _orders = [];
  bool _loaded = false;

  List<Order> get allOrders => List.unmodifiable(_orders);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    _orders.addAll(MockOrderData.seedOrders);

    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        final saved = list
            .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        for (final order in saved) {
          if (!_orders.any((o) => o.id == order.id)) {
            _orders.insert(0, order);
          }
        }
      } catch (_) {}
    }

    _orders.sort((a, b) => b.placedAt.compareTo(a.placedAt));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_orders.map((e) => e.toMap()).toList()),
    );
  }

  Future<Order> addOrder(Order order) async {
    _orders.insert(0, order);
    await _save();
    return order;
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
      await _save();
    }
  }

  List<Order> getByStudent(String studentId) =>
      _orders.where((o) => o.studentId == studentId).toList();

  List<Order> getActive() => _orders.where((o) => o.isActive).toList();
  List<Order> getCompleted() => _orders.where((o) => o.isCompleted).toList();

  Order? findByToken(String token) {
    try {
      return _orders.firstWhere((o) => o.token == token);
    } catch (_) {
      return null;
    }
  }

  Order? findById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Order> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return _orders;
    return _orders.where((o) {
      return o.token.contains(q) ||
          o.id.toLowerCase().contains(q) ||
          o.studentName.toLowerCase().contains(q) ||
          o.items.any((i) => i.name.toLowerCase().contains(q));
    }).toList();
  }

  Order createNewOrder({
    required String studentId,
    required String studentName,
    required String studentDept,
    required List<OrderItem> items,
    required double total,
    required String paymentMethod,
    DateTime? scheduledFor,
  }) {
    final orderId = AppUtils.generateOrderId();
    final token = AppUtils.extractTokenFromOrderId(orderId);
    return Order(
      id: orderId,
      token: token,
      studentId: studentId,
      studentName: studentName,
      studentDept: studentDept,
      items: items,
      total: total,
      paymentMethod: paymentMethod,
      status: scheduledFor != null ? 'Scheduled' : 'Preparing',
      isScheduled: scheduledFor != null,
      scheduledFor: scheduledFor,
      placedAt: DateTime.now(),
      qrContent: AppUtils.buildQrContent(orderId, token),
    );
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) => OrderRepository());

class OrderNotifier extends Notifier<List<Order>> {
  late OrderRepository _repo;

  @override
  List<Order> build() {
    _repo = ref.read(orderRepositoryProvider);
    return List.from(_repo.allOrders);
  }

  Future<void> load() async {
    await _repo.load();
    state = List.from(_repo.allOrders);
  }

  Future<Order> placeOrder({
    required String studentId,
    required String studentName,
    required String studentDept,
    required List<OrderItem> items,
    required double total,
    required String paymentMethod,
    DateTime? scheduledFor,
  }) async {
    final order = _repo.createNewOrder(
      studentId: studentId,
      studentName: studentName,
      studentDept: studentDept,
      items: items,
      total: total,
      paymentMethod: paymentMethod,
      scheduledFor: scheduledFor,
    );
    await _repo.addOrder(order);
    state = List.from(_repo.allOrders);
    return order;
  }

  Future<void> updateStatus(String orderId, String status) async {
    await _repo.updateStatus(orderId, status);
    state = List.from(_repo.allOrders);
  }

  List<Order> getByStudent(String studentId) => _repo.getByStudent(studentId);
  List<Order> getActive() => _repo.getActive();
  List<Order> getCompleted() => _repo.getCompleted();
  Order? findByToken(String token) => _repo.findByToken(token);
  Order? findById(String id) => _repo.findById(id);
  List<Order> search(String q) => _repo.search(q);
}

final orderProvider = NotifierProvider<OrderNotifier, List<Order>>(() {
  return OrderNotifier();
});
