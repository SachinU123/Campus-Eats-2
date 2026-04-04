import 'package:flutter/material.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/models/order.dart';

class OrderSlipScreen extends StatelessWidget {
  final Order order;
  const OrderSlipScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Digital Receipt'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          // Receipt Container
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'CampusEats',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'OFFICIAL RECEIPT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Customer / Payment Section
              _ReceiptRow(label: 'Customer', value: order.studentName),
              const SizedBox(height: 8),
              _ReceiptRow(
                label: 'Date',
                value: '${AppUtils.formatDate(order.placedAt)} ${AppUtils.formatTimeShort(order.placedAt)}',
              ),
              const SizedBox(height: 8),
              _ReceiptRow(label: 'Payment Method', value: order.paymentMethod),
              const SizedBox(height: 8),
              _ReceiptRow(
                label: 'Payment Status',
                value: 'Paid',
                valueColor: AppColors.primary,
              ),
              const SizedBox(height: 8),
              _ReceiptRow(
                label: 'Token',
                value: order.token,
                valueStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Items Section
              const Text(
                'ORDERED ITEMS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              ...order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.quantity}x',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@ Rs. ${item.price.toStringAsFixed(0)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 16),

              // Summary Section
              _ReceiptRow(
                label: 'Subtotal',
                value: 'Rs. ${order.total.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Rs. ${order.total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Thank you for using CampusEats!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: valueStyle ?? TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
