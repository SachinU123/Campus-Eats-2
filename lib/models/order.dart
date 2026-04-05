import 'package:intl/intl.dart';
import 'order_item.dart';

class Order {
  final String id;
  final String token;
  final String studentId;
  final String studentName;
  final String studentDept;
  final List<OrderItem> items;
  final double total;
  final String paymentMethod;
  final String status; // Preparing / Verified / Collected / Cancelled
  final bool isScheduled;
  final DateTime? scheduledFor;
  final DateTime? estimatedReadyAt; // ETA for immediate orders (null = unknown)
  final DateTime placedAt;
  final String qrContent; // ORDER_CE-TOKEN_XXXX

  const Order({
    required this.id,
    required this.token,
    required this.studentId,
    required this.studentName,
    required this.studentDept,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.placedAt,
    required this.qrContent,
    this.isScheduled = false,
    this.scheduledFor,
    this.estimatedReadyAt,
  });

  Order copyWith({
    String? id,
    String? token,
    String? studentId,
    String? studentName,
    String? studentDept,
    List<OrderItem>? items,
    double? total,
    String? paymentMethod,
    String? status,
    bool? isScheduled,
    DateTime? scheduledFor,
    DateTime? estimatedReadyAt,
    DateTime? placedAt,
    String? qrContent,
  }) {
    return Order(
      id: id ?? this.id,
      token: token ?? this.token,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentDept: studentDept ?? this.studentDept,
      items: items ?? this.items,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      estimatedReadyAt: estimatedReadyAt ?? this.estimatedReadyAt,
      placedAt: placedAt ?? this.placedAt,
      qrContent: qrContent ?? this.qrContent,
    );
  }

  bool get isCompleted => status == 'Collected';
  bool get isActive => !isCompleted && status != 'Cancelled';
  bool get isCancelled => status == 'Cancelled';

  /// Returns a human-readable time label for the order.
  /// - Scheduled orders: "Pickup at h:mm a" (e.g. "Pickup at 11:30 AM")
  /// - Immediate orders with ETA: "Ready by h:mm a" (e.g. "Ready by 11:06 PM")
  /// - No info: null
  String? get etaLabel {
    final fmt = DateFormat('h:mm a'); // 12-hour local time, no leading zero
    if (isScheduled && scheduledFor != null) {
      return 'Pickup at ${fmt.format(scheduledFor!)}';
    }
    if (estimatedReadyAt != null) {
      return 'Ready by ${fmt.format(estimatedReadyAt!)}';
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'token': token,
      'studentId': studentId,
      'studentName': studentName,
      'studentDept': studentDept,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'paymentMethod': paymentMethod,
      'status': status,
      'isScheduled': isScheduled,
      'scheduledFor': scheduledFor?.toIso8601String(),
      'estimatedReadyAt': estimatedReadyAt?.toIso8601String(),
      'placedAt': placedAt.toIso8601String(),
      'qrContent': qrContent,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      token: map['token'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      studentDept: map['studentDept'] as String? ?? '',
      items: (map['items'] as List)
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String,
      status: map['status'] as String,
      isScheduled: map['isScheduled'] as bool? ?? false,
      scheduledFor: map['scheduledFor'] != null
          ? DateTime.parse(map['scheduledFor'] as String)
          : null,
      estimatedReadyAt: map['estimatedReadyAt'] != null
          ? DateTime.parse(map['estimatedReadyAt'] as String)
          : null,
      placedAt: DateTime.parse(map['placedAt'] as String),
      qrContent: map['qrContent'] as String,
    );
  }
}
