import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/models/order.dart';

class StudentOrdersScreen extends ConsumerWidget {
  const StudentOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = ref.watch(orderProvider); // watch for rebuild
    final user = ref.watch(authProvider);

    final myOrders = user != null
        ? ref.read(orderProvider.notifier).getByStudent(user.id)
        : <Order>[];

    final active = myOrders.where((o) => o.isActive).toList();
    final completed = myOrders.where((o) => o.isCompleted).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(orders: active, empty: 'No active orders'),
            _OrderList(orders: completed, empty: 'No completed orders'),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final String empty;

  const _OrderList({required this.orders, required this.empty});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: empty,
        subtitle: 'Your orders will appear here',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _StudentOrderCard(order: orders[i]),
    );
  }
}

class _StudentOrderCard extends StatelessWidget {
  final Order order;
  const _StudentOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => context.push('/student/orders/${order.id}', extra: order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${order.token}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  order.id,
                  style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 0.5),
                ),
              ),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 10),

          if (order.isScheduled && order.scheduledFor != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF00838F)),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled for ${AppUtils.formatTimeShort(order.scheduledFor!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00838F),
                    ),
                  ),
                ],
              ),
            ),

          // Items list
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item.name} x${item.quantity}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      'Rs. ${item.lineTotal.toInt()}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              )),

          const Divider(height: 16),

          Row(
            children: [
              Text(
                AppUtils.formatDateTime(order.placedAt),
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                'Rs. ${order.total.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.payment_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(order.paymentMethod, style: theme.textTheme.bodySmall),
              const Spacer(),
              Text(
                'View Details',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}
