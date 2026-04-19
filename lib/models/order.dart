import 'package:intl/intl.dart';
import 'order_item.dart';

class Order {
  final String id;
  final String token;
  final String studentId;
  final String studentName;
  final String studentDept;
  final String customerRole; // 'student' | 'faculty'
  final String facultyName;  // set when customerRole == 'faculty'
  final String facultyRoom;  // faculty cabin/office number
  final String facultyDept;  // faculty department
  final List<OrderItem> items;
  final double total;
  final String paymentMethod;
  final String status; // Preparing / Verified / Collected / Cancelled
  final bool isScheduled;
  final DateTime? scheduledFor;
  final DateTime? estimatedReadyAt; // ETA for immediate orders (null = unknown)
  final DateTime placedAt;
  final String qrContent; // ORDER_CE-TOKEN_XXXX
  final DateTime? printedAt; // set when canteen prints the slip; separate from completed
  final DateTime? readyAt;  // Phase 11: set when canteen marks order READY; triggers push

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
    this.customerRole = 'student',
    this.facultyName = '',
    this.facultyRoom = '',
    this.facultyDept = '',
    this.isScheduled = false,
    this.scheduledFor,
    this.estimatedReadyAt,
    this.printedAt,
    this.readyAt,
  });

  Order copyWith({
    String? id,
    String? token,
    String? studentId,
    String? studentName,
    String? studentDept,
    String? customerRole,
    String? facultyName,
    String? facultyRoom,
    String? facultyDept,
    List<OrderItem>? items,
    double? total,
    String? paymentMethod,
    String? status,
    bool? isScheduled,
    DateTime? scheduledFor,
    DateTime? estimatedReadyAt,
    DateTime? placedAt,
    String? qrContent,
    DateTime? printedAt,
    bool clearPrintedAt = false,
    DateTime? readyAt,
    bool clearReadyAt = false,
  }) {
    return Order(
      id: id ?? this.id,
      token: token ?? this.token,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentDept: studentDept ?? this.studentDept,
      customerRole: customerRole ?? this.customerRole,
      facultyName: facultyName ?? this.facultyName,
      facultyRoom: facultyRoom ?? this.facultyRoom,
      facultyDept: facultyDept ?? this.facultyDept,
      items: items ?? this.items,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      estimatedReadyAt: estimatedReadyAt ?? this.estimatedReadyAt,
      placedAt: placedAt ?? this.placedAt,
      qrContent: qrContent ?? this.qrContent,
      printedAt: clearPrintedAt ? null : (printedAt ?? this.printedAt),
      readyAt: clearReadyAt ? null : (readyAt ?? this.readyAt),
    );
  }

  bool get isCompleted => status == 'Collected';
  bool get isCancelled => status == 'Cancelled';
  bool get isPrinted => printedAt != null; // canteen-only concept: slip has been printed
  bool get isReady  => readyAt != null;   // Phase 11: canteen explicitly marked ready for pickup
  // isActive = not finished (not completed, not cancelled).
  // NOTE: printed and ready orders are still active from the student's perspective —
  // the student still needs to collect their food and show their QR.
  // isPrinted and isReady are CANTEEN-UI concepts and must NOT affect this getter.
  bool get isActive => !isCompleted && !isCancelled;

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
      'customerRole': customerRole,
      'facultyName': facultyName,
      'facultyRoom': facultyRoom,
      'facultyDept': facultyDept,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'paymentMethod': paymentMethod,
      'status': status,
      'isScheduled': isScheduled,
      'scheduledFor': scheduledFor?.toIso8601String(),
      'estimatedReadyAt': estimatedReadyAt?.toIso8601String(),
      'placedAt': placedAt.toIso8601String(),
      'qrContent': qrContent,
      'printedAt': printedAt?.toIso8601String(),
      'readyAt': readyAt?.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      token: map['token'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      studentDept: map['studentDept'] as String? ?? '',
      customerRole: map['customerRole'] as String? ?? 'student',
      facultyName: map['facultyName'] as String? ?? '',
      facultyRoom: map['facultyRoom'] as String? ?? '',
      facultyDept: map['facultyDept'] as String? ?? '',
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
      printedAt: map['printedAt'] != null
          ? DateTime.parse(map['printedAt'] as String)
          : null,
      readyAt: map['readyAt'] != null
          ? DateTime.parse(map['readyAt'] as String)
          : null,
    );
  }
}
