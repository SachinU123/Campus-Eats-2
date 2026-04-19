import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/constants/app_design_tokens.dart';
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

    Future<void> onRefresh() async {
      await ref.read(orderProvider.notifier).reload();
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: const TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radio_button_checked_rounded, size: 14),
                    SizedBox(width: 6),
                    Text('Active'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 14),
                    SizedBox(width: 6),
                    Text('Completed'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(
              orders: active,
              emptyTitle: 'No active orders',
              emptySubtitle:
                  'Place an order from the menu and it will appear here.',
              emptyIcon: Icons.shopping_bag_outlined,
              isActive: true,
              onRefresh: onRefresh,
            ),
            _OrderList(
              orders: completed,
              emptyTitle: 'No completed orders',
              emptySubtitle:
                  'Completed and collected orders will show here.',
              emptyIcon: Icons.check_circle_outline_rounded,
              isActive: false,
              onRefresh: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final bool isActive;
  final Future<void> Function() onRefresh;

  const _OrderList({
    required this.orders,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.isActive,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 420,
            child: EmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxxl),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (ctx, i) =>
            _StudentOrderCard(order: orders[i], isActiveTab: isActive),
      ),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          // ── Header row ────────────────────────────────────────────
          Row(
            children: [
              StatusChip(status: order.status),
              const Spacer(),
              if (order.isScheduled && order.scheduledFor != null)
                _TimeTag(
                  icon: Icons.schedule_rounded,
                  label: 'Pickup ${AppUtils.formatTimeShort(order.scheduledFor!)}',
                  color: AppColors.statusScheduled,
                )
              else if (order.isActive && order.estimatedReadyAt != null)
                _TimeTag(
                  icon: Icons.timer_outlined,
                  label: order.etaLabel ?? '',
                  color: AppColors.warning,
                )
              else
                Text(
                  AppUtils.formatDateTime(order.placedAt),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),

          // ── Token (active only) ───────────────────────────────────
          if (widget.isActiveTab) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Token  ',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    '#${order.token}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // ── Items ─────────────────────────────────────────────────
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${item.quantity}× ${item.name}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Rs. ${item.lineTotal.toInt()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              )),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, thickness: 1),
          ),

          // ── Total row ─────────────────────────────────────────────
          Row(
            children: [
              Text(
                'Total',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'Rs. ${order.total.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          // ── Active actions ────────────────────────────────────────
          if (widget.isActiveTab) ...[
            const SizedBox(height: AppSpacing.lg),
            if (_showQr) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.dividerLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: order.qrContent,
                    version: QrVersions.auto,
                    size: 150,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showQr = !_showQr),
                    icon: Icon(
                      _showQr
                          ? Icons.visibility_off_rounded
                          : Icons.qr_code_rounded,
                      size: 17,
                    ),
                    label: Text(_showQr ? 'Hide QR' : 'Show QR'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderSlipScreen(order: order),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 17),
                    label: const Text('View Slip'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11)),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          OrderDetailScreen(orderId: order.id, order: order),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View Details'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TimeTag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
