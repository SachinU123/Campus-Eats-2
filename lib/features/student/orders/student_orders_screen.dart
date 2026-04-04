import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/features/student/orders/order_detail_screen.dart';
import 'package:campus_eats_ag/features/student/orders/order_slip_screen.dart';
import 'package:campus_eats_ag/models/order.dart';

class StudentOrdersScreen extends ConsumerWidget {
  const StudentOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = ref.watch(orderProvider);
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
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(orders: active, empty: 'No active orders', isActive: true),
            _OrderList(orders: completed, empty: 'No completed orders', isActive: false),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final String empty;
  final bool isActive;

  const _OrderList({required this.orders, required this.empty, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_rounded,
        title: empty,
        subtitle: 'Your orders will appear here',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) => _StudentOrderCard(order: orders[i], isActiveTab: isActive),
    );
  }
}

class _StudentOrderCard extends StatefulWidget {
  final Order order;
  final bool isActiveTab;
  const _StudentOrderCard({required this.order, required this.isActiveTab});

  @override
  State<_StudentOrderCard> createState() => _StudentOrderCardState();
}

class _StudentOrderCardState extends State<_StudentOrderCard> {
  bool _showQr = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;

    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id, order: order),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(status: order.status),
              const Spacer(),
              if (order.isScheduled && order.scheduledFor != null)
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF00ACC1)),
                    const SizedBox(width: 4),
                    Text(
                      AppUtils.formatTimeShort(order.scheduledFor!),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00ACC1),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  AppUtils.formatDateTime(order.placedAt),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (widget.isActiveTab) ...[
            Row(
              children: [
                Text(
                  'Token: ',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  '#${order.token}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.name}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Rs. ${item.lineTotal.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              )),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1),
          ),

          Row(
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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

          if (widget.isActiveTab) ...[
            const SizedBox(height: 16),
            if (_showQr) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dividerLight),
                  ),
                  child: QrImageView(
                    data: order.qrContent,
                    version: QrVersions.auto,
                    size: 140,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showQr = !_showQr),
                    icon: Icon(
                      _showQr ? Icons.visibility_off_rounded : Icons.qr_code_rounded,
                      size: 18,
                    ),
                    label: Text(_showQr ? 'Hide QR' : 'Show QR'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderSlipScreen(order: order),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('Slip'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: order.id, order: order),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
