import 'dart:developer' as dev;
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
        } catch (e) {
          dev.log('[ORDER] parse error: $e', name: 'OrderRepo');
        }
      }
      _orders.sort((a, b) => b.placedAt.compareTo(a.placedAt));
      dev.log('[ORDER] Loaded ${_orders.length} orders', name: 'OrderRepo');
    } else {
      dev.log('[ORDER] load failed: ${result.message}', name: 'OrderRepo');
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
    DateTime? scheduledFor,
  }) async {
    final body = <String, dynamic>{
      'items': items,
      'notes': ?notes,
      if (scheduledFor != null)
        'scheduledFor': scheduledFor.toUtc().toIso8601String(),
    };

    final result = await _api.post('/orders', body: body);

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

  /// Fetch real report data from the backend.
  Future<Map<String, dynamic>?> getReports() async {
    final result = await _api.get('/canteen/reports');
    if (!result.isSuccess) {
      dev.log('[REPORTS] fetch failed: ${result.message}', name: 'OrderRepo');
      return null;
    }
    dev.log('[REPORTS] fetch OK', name: 'OrderRepo');
    return result.data as Map<String, dynamic>?;
  }

  /// Clear all completed orders (canteen only).
  Future<int> clearCompletedHistory() async {
    final result = await _api.delete('/canteen/history/completed');
    if (!result.isSuccess) {
      throw Exception(result.message);
    }
    final data = result.data as Map<String, dynamic>?;
    return (data?['cleared'] as int?) ?? 0;
  }

  /// Lightweight poll — returns { count, latestOrderedAt } only.
  /// Used by the smart-poll mechanism to detect new orders without
  /// fetching the full order list on every tick.
  Future<({int count, String? latestOrderedAt})> pollOrderQueue() async {
    final result = await _api.get('/canteen/orders/poll');
    if (!result.isSuccess) {
      dev.log('[POLL] poll failed: ${result.message}', name: 'OrderRepo');
      return (count: 0, latestOrderedAt: null);
    }
    final data = result.data as Map<String, dynamic>? ?? {};
    return (
      count: (data['count'] as int?) ?? 0,
      latestOrderedAt: data['latestOrderedAt'] as String?,
    );
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

  /// Mark an order's slip as printed (idempotent).
  /// This moves the order out of the active queue into the Printed bucket.
  Future<void> printOrder(String orderId) async {
    final result = await _api.patch('/canteen/orders/$orderId/print', body: {});
    if (result.isSuccess) {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] =
            _orders[index].copyWith(printedAt: DateTime.now());
      }
    } else {
      throw Exception(result.message);
    }
  }

  /// Mark an order as READY for pickup (Phase 11).
  /// Separate from printedAt and completedAt.
  /// Triggers a push notification to the customer via backend.
  Future<void> markReady(String orderId) async {
    final result = await _api.patch('/canteen/orders/$orderId/ready', body: {});
    if (result.isSuccess) {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = _orders[index].copyWith(readyAt: DateTime.now());
      }
    } else {
      throw Exception(result.message);
    }
  }

  /// Verify an order by token (or QR content) via backend.
  /// Returns a map with keys: found, reason, message, and optionally order.
  /// Reasons: TOKEN_NOT_FOUND, INVALID_TOKEN, NOT_PAID, CANCELLED,
  ///          ALREADY_COMPLETED, COMPLETED
  Future<VerifyResult> verifyByToken(String rawToken) async {
    // Support QR format: ORDER_CE-TOKEN_XXXX or just the 4-digit token
    final token = _extractToken(rawToken);

    final result = await _api.post('/canteen/orders/verify', body: {'token': token});
    if (!result.isSuccess) {
      return VerifyResult(
        found: false,
        reason: 'API_ERROR',
        message: result.message,
      );
    }

    final data = result.data as Map<String, dynamic>;
    final found = data['found'] as bool? ?? false;
    final reason = data['reason'] as String? ?? 'UNKNOWN';
    final message = data['message'] as String? ?? '';
    Order? order;
    if (found && data['order'] != null) {
      try {
        order = _parseOrder(data['order'] as Map<String, dynamic>);
      } catch (_) {}
    }

    return VerifyResult(found: found, reason: reason, message: message, order: order);
  }

  /// Extract a 4-digit token from a QR content string or bare token.
  /// QR format: ORDER_CE-TOKEN_XXXX or ORDER_CE-XXXX_TOKEN_XXXX
  String _extractToken(String raw) {
    final trimmed = raw.trim();
    // Try to extract 4-digit token from the QR content
    // Format: ORDER_CE-TOKEN_XXXX_TOKEN_XXXX  or  ORDER_CE-XXXX_TOKEN_XXXX
    final tokenMatch = RegExp(r'TOKEN_(\d{4})').firstMatch(trimmed);
    if (tokenMatch != null) return tokenMatch.group(1)!;
    // If pure 4-digit number, use as-is
    if (RegExp(r'^\d{4}$').hasMatch(trimmed)) return trimmed;
    // Otherwise return as-is (backend will reject invalid)
    return trimmed;
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
          o.facultyName.toLowerCase().contains(q) ||
          o.items.any((i) => i.name.toLowerCase().contains(q));
    }).toList();
  }

  // ─── Parse Backend Response to Order Model ─────────────────

  Order _parseOrder(Map<String, dynamic> data) {
    final token = data['tokenNumber'] as String? ?? '';
    final id = data['id'] as String;
    final studentData = data['student'] as Map<String, dynamic>?;
    final facultyData = data['faculty'] as Map<String, dynamic>?;
    final customerRole = data['customerRole'] as String? ?? 'student';

    // Parse schedule / ETA fields — backend sends UTC ISO strings.
    // Call .toLocal() explicitly so all DateTime values are in device-local
    // time (IST on campus devices), not UTC.
    final scheduledForStr = data['scheduledFor'] as String?;
    final estimatedReadyAtStr = data['estimatedReadyAt'] as String?;
    final scheduledFor = scheduledForStr != null
        ? DateTime.tryParse(scheduledForStr)?.toLocal()
        : null;
    final estimatedReadyAt = estimatedReadyAtStr != null
        ? DateTime.tryParse(estimatedReadyAtStr)?.toLocal()
        : null;
    final placedAt =
        (DateTime.tryParse(data['orderedAt'] as String? ?? '') ?? DateTime.now())
            .toLocal();

    // Determine display name: for faculty orders use faculty name; for students use student name.
    final isFaculty = customerRole == 'faculty';
    final displayName = isFaculty
        ? (facultyData?['name'] as String? ?? '')
        : (studentData?['name'] as String? ?? '');

    return Order(
      id: id,
      token: token,
      studentId: data['studentId'] as String? ?? '',
      studentName: displayName,
      studentDept: '',
      customerRole: customerRole,
      facultyName: facultyData?['name'] as String? ?? '',
      facultyRoom: facultyData?['roomNumber'] as String? ?? '',
      facultyDept: facultyData?['department'] as String? ?? '',
      items: _parseItems(data['items'] as List? ?? []),
      total: (data['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: data['paymentMethod'] as String? ?? 'razorpay',
      status: _mapStatus(data['status'] as String? ?? 'created'),
      isScheduled: scheduledFor != null,
      scheduledFor: scheduledFor,
      estimatedReadyAt: estimatedReadyAt,
      placedAt: placedAt,
      qrContent: 'ORDER_CE-${token}_TOKEN_$token',
      printedAt: data['printedAt'] != null
          ? DateTime.tryParse(data['printedAt'] as String)?.toLocal()
          : null,
      readyAt: data['readyAt'] != null
          ? DateTime.tryParse(data['readyAt'] as String)?.toLocal()
          : null,
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

// ─── Verify Result ─────────────────────────────────────────────

class VerifyResult {
  final bool found;
  final String reason;
  final String message;
  final Order? order;

  const VerifyResult({
    required this.found,
    required this.reason,
    required this.message,
    this.order,
  });

  bool get isCompleted => reason == 'COMPLETED';
  bool get isAlreadyCompleted => reason == 'ALREADY_COMPLETED';
  bool get isNotFound => reason == 'TOKEN_NOT_FOUND';
  bool get isInvalid => reason == 'INVALID_TOKEN' || reason == 'API_ERROR';
  bool get isNotPaid => reason == 'NOT_PAID';
  bool get isCancelled => reason == 'CANCELLED';
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
    final orderItems = items
        .map((i) => {
              'menuItemId': i.menuItemId,
              'quantity': i.quantity,
            })
        .toList();

    final order = await _repo.createOrder(
      items: orderItems,
      scheduledFor: scheduledFor,
    );
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
  Future<VerifyResult> verifyByToken(String rawToken) =>
      _repo.verifyByToken(rawToken);
  Order? findById(String id) => _repo.findById(id);
  List<Order> search(String q) => _repo.search(q);
}

final orderProvider = NotifierProvider<OrderNotifier, List<Order>>(() {
  return OrderNotifier();
});
