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

    // Earliest allowed pickup = now + 30 minutes (minimum lead time).
    // We snap this forward to the next 30-minute wall-clock bucket so that
    // every visible slot is always >= 30 min away from the current time.
    final earliest = now.add(const Duration(minutes: 30));

    // Strip seconds/milliseconds, then round UP to the next 30-min mark.
    final base = DateTime(earliest.year, earliest.month, earliest.day,
        earliest.hour, earliest.minute);
    final remainder = base.minute % 30;
    final firstSlot = remainder == 0
        ? base // already on a 30-min boundary
        : base.add(Duration(minutes: 30 - remainder));

    // Maximum pickup = now + 2 hours (120 minutes).
    final maxTime = now.add(const Duration(minutes: 120));

    final slots = <DateTime>[];
    DateTime slot = firstSlot;
    while (!slot.isAfter(maxTime)) {
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
