class PendingAction {
  final String id;
  final String type; // mark_ready, mark_verified, mark_collected
  final String orderId;
  final String token;
  final DateTime timestamp;
  String status; // pending, synced, failed

  PendingAction({
    required this.id,
    required this.type,
    required this.orderId,
    required this.token,
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'orderId': orderId,
      'token': token,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory PendingAction.fromMap(Map<String, dynamic> map) {
    return PendingAction(
      id: map['id'] as String,
      type: map['type'] as String,
      orderId: map['orderId'] as String,
      token: map['token'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: map['status'] as String? ?? 'pending',
    );
  }
}

class DailyReport {
  final String date;
  final int totalOrders;
  final double totalRevenue;

  const DailyReport({
    required this.date,
    required this.totalOrders,
    required this.totalRevenue,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
      };

  factory DailyReport.fromMap(Map<String, dynamic> map) => DailyReport(
        date: map['date'] as String,
        totalOrders: map['totalOrders'] as int,
        totalRevenue: (map['totalRevenue'] as num).toDouble(),
      );
}

class TopItem {
  final String name;
  final int count;

  const TopItem({required this.name, required this.count});
}

class MonthlyReportSummary {
  final String month; // e.g. "March 2026"
  final double totalSales;
  final int totalOrders;
  final List<TopItem> topItems;

  const MonthlyReportSummary({
    required this.month,
    required this.totalSales,
    required this.totalOrders,
    required this.topItems,
  });
}
