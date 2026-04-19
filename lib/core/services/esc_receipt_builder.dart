/// ─── CampusEats — ESC/POS Receipt Builder (Phase 11) ────────────────────────
///
/// Builds a print [Ticket] from an [Order] using the real
/// unified_esc_pos_printer v3.2.0 API (verified from package source).
///
/// Ticket API used:
///   ticket.text(str, style: PrintTextStyle(), align: PrintAlign)
///   ticket.row([PrintColumn(text, flex, align, style)])
///   ticket.separator()           — horizontal rule (alias: separator())
///   ticket.emptyLines([n])
///   ticket.cut()
///
/// PrintColumn uses `flex` (not `width`) for proportional column sizing.
/// Ticket.bytes → List[int] for raw send.

library;

import 'dart:developer' as dev;
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/models/order.dart';

class EscReceiptBuilder {
  EscReceiptBuilder._();

  /// Builds an 80mm receipt [Ticket] from [order].
  /// Returns null on any error — callers MUST fall back to PDF printing.
  static Future<Ticket?> buildTicket(Order order) async {
    try {
      final profile = await CapabilityProfile.load();
      final ticket  = Ticket(PaperSize.mm80, profile);

      // ── Header ──────────────────────────────────────────────────────────
      ticket.text(
        'CAMPUS EATS',
        style: const PrintTextStyle(bold: true, height: TextSize.size2, width: TextSize.size2),
        align: PrintAlign.center,
      );
      ticket.separator();

      // ── Token ────────────────────────────────────────────────────────────
      ticket.text(
        '#${order.token}',
        style: const PrintTextStyle(bold: true, height: TextSize.size3, width: TextSize.size3),
        align: PrintAlign.center,
      );
      ticket.text(
        order.customerRole == 'faculty' ? 'FACULTY ORDER' : 'STUDENT ORDER',
        style: const PrintTextStyle(bold: true),
        align: PrintAlign.center,
      );
      ticket.separator();

      // ── Customer details ─────────────────────────────────────────────────
      _row(ticket, 'Name', order.studentName);
      if (order.customerRole == 'faculty') {
        if (order.facultyDept.isNotEmpty) _row(ticket, 'Dept', order.facultyDept);
        if (order.facultyRoom.isNotEmpty) _row(ticket, 'Room', order.facultyRoom);
      }
      _row(ticket, 'Time', AppUtils.formatDateTime(order.placedAt));
      if (order.isScheduled && order.scheduledFor != null) {
        _row(ticket, 'Pickup', AppUtils.formatTimeShort(order.scheduledFor!));
      } else if (order.estimatedReadyAt != null) {
        _row(ticket, 'ETA', AppUtils.formatTimeShort(order.estimatedReadyAt!));
      }
      _row(ticket, 'Payment', 'PAID UPI');
      ticket.separator();

      // ── Items ─────────────────────────────────────────────────────────────
      ticket.text('ORDER ITEMS', style: const PrintTextStyle(bold: true, underline: true));
      ticket.emptyLines(1);

      for (final item in order.items) {
        // flex = 7 | 1 | 4 → proportional to 12 total
        ticket.row([
          PrintColumn(
            text:  _trunc(item.name, 22),
            flex:  7,
            style: const PrintTextStyle(bold: true),
            align: PrintAlign.left,
          ),
          PrintColumn(
            text:  'x${item.quantity}',
            flex:  1,
            align: PrintAlign.center,
          ),
          PrintColumn(
            text:  'Rs.${item.lineTotal.toInt()}',
            flex:  4,
            style: const PrintTextStyle(bold: true),
            align: PrintAlign.right,
          ),
        ]);
      }

      ticket.separator();

      // ── Total ─────────────────────────────────────────────────────────────
      ticket.row([
        PrintColumn(
          text:  'TOTAL',
          flex:  6,
          style: const PrintTextStyle(bold: true, height: TextSize.size2),
          align: PrintAlign.left,
        ),
        PrintColumn(
          text:  'Rs.${order.total.toInt()}',
          flex:  6,
          style: const PrintTextStyle(bold: true, height: TextSize.size2),
          align: PrintAlign.right,
        ),
      ]);

      ticket.separator();
      ticket.text('Thank you! Visit CampusEats again.', align: PrintAlign.center);
      ticket.emptyLines(3);
      ticket.cut();

      return ticket;
    } catch (e, st) {
      dev.log('[ESC] Ticket build failed: $e\n$st', name: 'EscReceiptBuilder');
      return null;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static void _row(Ticket ticket, String label, String value) {
    ticket.row([
      PrintColumn(
        text:  _trunc('$label:', 10),
        flex:  4,
        align: PrintAlign.left,
      ),
      PrintColumn(
        text:  _trunc(value, 30),
        flex:  8,
        style: const PrintTextStyle(bold: true),
        align: PrintAlign.left,
      ),
    ]);
  }

  /// Truncates string to [max] characters to prevent receipt overflow.
  static String _trunc(String str, int max) =>
      str.length <= max ? str : '${str.substring(0, max - 1)}\u2026';
}
