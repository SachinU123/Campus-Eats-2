import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/data/repositories/cart_repository.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/models/order_item.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> extra;

  const PaymentScreen({super.key, required this.extra});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isLoading = false;

  // Only UPI is available
  static const String _method = 'UPI';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = (widget.extra['subtotal'] as num?)?.toDouble() ?? 0;
    final scheduledForStr = widget.extra['scheduledFor'] as String?;
    final scheduledFor =
        scheduledForStr != null ? DateTime.parse(scheduledForStr) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_rounded,
                                color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Order Summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Subtotal'),
                            const Spacer(),
                            Text(
                              'Rs. ${subtotal.toInt()}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Text('Convenience Fee'),
                            Spacer(),
                            Text('Free',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16)),
                            const Spacer(),
                            Text(
                              'Rs. ${subtotal.toInt()}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (scheduledFor != null) ...[
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 16, color: Color(0xFF00838F)),
                              const SizedBox(width: 6),
                              Text(
                                'Scheduled for ${TimeOfDay.fromDateTime(scheduledFor).format(context)}',
                                style: const TextStyle(
                                  color: Color(0xFF00838F),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Payment Method',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),

                  // UPI only — single, pre-selected card
                  AppCard(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UPI',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                'Google Pay, PhonePe, Paytm',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.radio_button_checked,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Security note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security_rounded,
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Payments are secure and encrypted',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              child: AppButton(
                label: 'Pay Rs. ${subtotal.toInt()} via UPI',
                isLoading: _isLoading,
                onTap: () => _processPayment(context, subtotal, scheduledFor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    double total,
    DateTime? scheduledFor,
  ) async {
    setState(() => _isLoading = true);

    // Simulate payment delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!context.mounted) return;

    final user = ref.read(authProvider);
    final cartItems = ref.read(cartProvider);
    final orderItems = cartItems.map(OrderItem.fromCartItem).toList();

    final order = await ref.read(orderProvider.notifier).placeOrder(
          studentId: user?.id ?? 'anon',
          studentName: user?.name ?? 'Student',
          studentDept: user?.department ?? '',
          items: orderItems,
          total: total,
          paymentMethod: _method,
          scheduledFor: scheduledFor,
        );

    await ref.read(cartProvider.notifier).clear();
    setState(() => _isLoading = false);

    if (context.mounted) {
      context.go('/student/success', extra: order);
    }
  }
}
