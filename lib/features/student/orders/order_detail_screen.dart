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
    final _ = ref.watch(orderProvider); // watch for rebuild
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
    final isCollected = order.status == 'Collected';
    final isReady = order.status == 'Ready';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.token}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status card
            AppCard(
              child: Row(
                children: [
                  StatusChip(status: order.status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage(order.status),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // QR section
            AppCard(
              child: Column(
                children: [
                  Text(
                    'Token #${order.token}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    opacity: isCollected ? 0.35 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isReady
                            ? Border.all(color: AppColors.success.withValues(alpha: 0.5), width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: order.qrContent,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCollected ? 'Already Collected' : 'Show this QR at counter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCollected
                          ? theme.colorScheme.onSurfaceVariant
                          : isReady
                              ? AppColors.success
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Order items
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items Ordered',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            VegBadge(isVeg: item.isVeg),
                            const SizedBox(width: 8),
                            Text(item.emoji),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              'x${item.quantity}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Rs. ${item.lineTotal.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const Spacer(),
                      Text(
                        'Rs. ${order.total.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Order meta
            AppCard(
              child: Column(
                children: [
                  _MetaRow(label: 'Order ID', value: order.id),
                  const Divider(height: 14),
                  _MetaRow(label: 'Placed At', value: AppUtils.formatDateTime(order.placedAt)),
                  const Divider(height: 14),
                  _MetaRow(label: 'Payment', value: order.paymentMethod),
                  if (order.isScheduled && order.scheduledFor != null) ...[
                    const Divider(height: 14),
                    _MetaRow(
                      label: 'Scheduled For',
                      value: AppUtils.formatTimeShort(order.scheduledFor!),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'Preparing': return 'Your food is being prepared. Visit the counter soon.';
      case 'Ready': return 'Your order is ready! Show your QR code at the counter.';
      case 'Scheduled': return 'Your order is scheduled. It will be prepared on time.';
      case 'Verified': return 'Your token was verified. Collect your food shortly.';
      case 'Collected': return 'Your order has been collected. Enjoy your meal!';
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
