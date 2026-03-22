import 'order_item.dart';

class Order {
  final String id; // e.g. CE-4892
  final String token; // e.g. 4892
  final String studentId;
  final String studentName;
  final String studentDept;
  final List<OrderItem> items;
  final double total;
  final String paymentMethod;
  final String status; // Preparing / Ready / Verified / Collected
  final bool isScheduled;
  final DateTime? scheduledFor;
  final DateTime placedAt;
  final String qrContent; // ORDER_CE-4892_TOKEN_4892

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
      placedAt: placedAt ?? this.placedAt,
      qrContent: qrContent ?? this.qrContent,
    );
  }

  bool get isCompleted => status == 'Collected';
  bool get isActive => !isCompleted;

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
      placedAt: DateTime.parse(map['placedAt'] as String),
      qrContent: map['qrContent'] as String,
    );
  }
}
