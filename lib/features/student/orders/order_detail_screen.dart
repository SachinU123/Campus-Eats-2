import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/models/order.dart';

class OrderDetailScreen extends ConsumerWidget {
  final Order? order;
  final String orderId;

  const OrderDetailScreen({super.key, this.order, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = ref.watch(orderProvider);
    final o = order ?? ref.read(orderProvider.notifier).findById(orderId);

    if (o == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return OrderDetailView(order: o);
  }
}

class OrderDetailView extends StatelessWidget {
  final Order order;
  const OrderDetailView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReady = order.status == 'Ready';
    final isActive = order.isActive; // True if order is NOT completed/cancelled

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.token}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Status block
            AppCard(
              child: Row(
                children: [
                  StatusChip(status: order.status),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _statusMessage(order.status),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // QR block (ONLY IF ACTIVE)
            if (isActive) ...[
              AppCard(
                child: Column(
                  children: [
                    Text(
                      'Token',
                      style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 1),
                    ),
                    Text(
                      '#${order.token}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isReady
                            ? Border.all(color: AppColors.success.withValues(alpha: 0.8), width: 3)
                            : Border.all(color: AppColors.dividerLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: order.qrContent,
                        version: QrVersions.auto,
                        size: 160,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isReady ? 'Your food is ready! Show this QR.' : 'Show this QR at the counter',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isReady ? AppColors.success : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Receipt Block
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rs. ${item.price.toInt()} x ${item.quantity}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Rs. ${item.lineTotal.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                      )),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const Spacer(),
                      Text(
                        'Rs. ${order.total.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Meta
            AppCard(
              child: Column(
                children: [
                  _MetaRow(label: 'Order ID', value: order.id),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  _MetaRow(label: 'Placed At', value: AppUtils.formatDateTime(order.placedAt)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  _MetaRow(label: 'Payment Method', value: order.paymentMethod),
                  if (order.isScheduled && order.scheduledFor != null) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                    _MetaRow(
                      label: 'Scheduled For',
                      value: AppUtils.formatTimeShort(order.scheduledFor!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'Preparing': return 'Your food is currently being prepared.';
      case 'Ready': return 'Your order is ready to be picked up!';
      case 'Scheduled': return 'Your order is scheduled for preparation.';
      case 'Verified': return 'Token verified. Collect your food shortly.';
      case 'Collected': return 'Your order has been collected successfully.';
      default: return 'Processing your order...';
    }
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
