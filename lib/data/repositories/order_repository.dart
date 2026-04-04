import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/data/api/api_client.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/models/order.dart';
import 'package:campus_eats_ag/models/order_item.dart';

class OrderRepository {
  final ApiClient _api;
  final List<Order> _orders = [];
  bool _loaded = false;

  OrderRepository(this._api);

  List<Order> get allOrders => List.unmodifiable(_orders);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    final result = await _api.get('/orders/my');
    if (result.isSuccess && result.data is List) {
      _orders.clear();
      for (final item in result.data as List) {
        try {
          _orders.add(_parseOrder(item as Map<String, dynamic>));
        } catch (_) {}
      }
      _orders.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    }
  }

  Future<void> reload() async {
    _loaded = false;
    _orders.clear();
    await load();
  }

  Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final result = await _api.post('/orders', body: {
      'items': items,
      // ignore: use_null_aware_elements
      if (notes != null) 'notes': notes,
    });

    if (!result.isSuccess) {
      throw Exception(result.message);
    }

    final order = _parseOrder(result.data as Map<String, dynamic>);
    _orders.insert(0, order);
    return order;
  }

  Future<Order?> getOrderById(String id) async {
    // Check local cache first
    final cached = _orders.where((o) => o.id == id).firstOrNull;
    if (cached != null) return cached;

    final result = await _api.get('/orders/$id');
    if (!result.isSuccess) return null;
    return _parseOrder(result.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>?> getSlip(String orderId) async {
    final result = await _api.get('/orders/$orderId/slip');
    if (!result.isSuccess) return null;
    return result.data as Map<String, dynamic>;
  }

  // ─── Canteen Methods ───────────────────────────────────────

  Future<List<Order>> getCanteenOrders({String? status}) async {
    final path = status != null
        ? '/canteen/orders?status=$status'
        : '/canteen/orders';
    final result = await _api.get(path);
    if (!result.isSuccess || result.data is! List) return [];

    return (result.data as List)
        .map((e) => _parseOrder(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    final result = await _api.patch('/canteen/orders/$orderId/complete', body: {
      'status': newStatus,
    });

    if (result.isSuccess) {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = _orders[index].copyWith(status: newStatus);
      }
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

  // ─── Parse Backend Response to Order Model ─────────────────

  Order _parseOrder(Map<String, dynamic> data) {
    final token = data['tokenNumber'] as String? ?? '';
    final id = data['id'] as String;
    final studentData = data['student'] as Map<String, dynamic>?;

    return Order(
      id: id,
      token: token,
      studentId: data['studentId'] as String? ?? '',
      studentName: studentData?['name'] as String? ?? '',
      studentDept: '',
      items: _parseItems(data['items'] as List? ?? []),
      total: (data['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: data['paymentMethod'] as String? ?? 'razorpay',
      status: _mapStatus(data['status'] as String? ?? 'created'),
      placedAt: DateTime.tryParse(data['orderedAt'] as String? ?? '') ??
          DateTime.now(),
      qrContent: 'ORDER_CE-${token}_TOKEN_$token',
    );
  }

  List<OrderItem> _parseItems(List items) {
    return items.map((e) {
      final m = e as Map<String, dynamic>;
      return OrderItem(
        menuItemId: m['menuItemId'] as String? ?? '',
        name: m['itemNameSnapshot'] as String? ?? m['name'] as String? ?? '',
        price: (m['unitPriceSnapshot'] as num? ?? m['price'] as num? ?? 0)
            .toDouble(),
        quantity: m['quantity'] as int? ?? 1,
        isVeg: m['isVeg'] as bool? ?? true,
        emoji: m['emoji'] as String? ?? '',
      );
    }).toList();
  }

  /// Map backend status to frontend display status.
  String _mapStatus(String backendStatus) {
    switch (backendStatus) {
      case 'created':
      case 'payment_pending':
        return 'Preparing';
      case 'paid':
        return 'Verified';
      case 'completed':
        return 'Collected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return backendStatus;
    }
  }
}

// ─── Providers ─────────────────────────────────────────────────

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(apiClientProvider));
});

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

  Future<void> reload() async {
    await _repo.reload();
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
    // Create order via API (total calculated server-side)
    final orderItems = items
        .map((i) => {
              'menuItemId': i.menuItemId,
              'quantity': i.quantity,
            })
        .toList();

    final order = await _repo.createOrder(items: orderItems);
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
