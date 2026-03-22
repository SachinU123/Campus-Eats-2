import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  static String formatPrice(double price) {
    final formatter = NumberFormat('##,##,##0.00', 'en_IN');
    return 'Rs. ${formatter.format(price)}';
  }

  static String formatPriceShort(double price) {
    if (price == price.truncateToDouble()) {
      return 'Rs. ${price.toInt()}';
    }
    return 'Rs. ${price.toStringAsFixed(2)}';
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static String formatTime(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  static String formatTimeShort(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  static List<DateTime> generateScheduleSlots() {
    final now = DateTime.now();
    final maxTime = now.add(const Duration(minutes: 150));
    final slots = <DateTime>[];

    // Round up to next 30-minute mark
    int minutesToAdd = 30 - (now.minute % 30);
    if (minutesToAdd == 0) minutesToAdd = 30;

    DateTime slot = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(Duration(minutes: minutesToAdd));

    while (slot.isBefore(maxTime) || slot.isAtSameMomentAs(maxTime)) {
      slots.add(slot);
      slot = slot.add(const Duration(minutes: 30));
    }

    return slots;
  }

  static String generateOrderId() {
    final now = DateTime.now();
    final token = (1000 + (now.millisecondsSinceEpoch % 9000)).toString();
    return 'CE-$token';
  }

  static String extractTokenFromOrderId(String orderId) {
    return orderId.replaceAll('CE-', '');
  }

  static String buildQrContent(String orderId, String token) {
    return 'ORDER_${orderId}_TOKEN_$token';
  }
}
