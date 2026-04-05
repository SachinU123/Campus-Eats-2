import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/models/order.dart';

// ─── Canteen-specific provider — always fetches from live backend ──────────
// This is SEPARATE from the student orderProvider which holds the student's
// own local-device order list. Canteen needs the full live DB view.
final canteenOrdersProvider =
    AsyncNotifierProvider<CanteenOrdersNotifier, List<Order>>(
  CanteenOrdersNotifier.new,
);

class CanteenOrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() => _fetch();

  Future<List<Order>> _fetch() async {
    dev.log('[CANTEEN] Fetching orders from backend...', name: 'CanteenOrders');
    final repo = ref.read(orderRepositoryProvider);
    final orders = await repo.getCanteenOrders();
    dev.log('[CANTEEN] Got ${orders.length} orders', name: 'CanteenOrders');
    return orders;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    dev.log('[CANTEEN] updateStatus orderId=$orderId status=$newStatus', name: 'CanteenOrders');
    final repo = ref.read(orderRepositoryProvider);
    await repo.updateStatus(orderId, newStatus);
    // Refresh to get authoritative server state
    await refresh();
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────

class CanteenOrdersScreen extends ConsumerStatefulWidget {
  const CanteenOrdersScreen({super.key});

  @override
  ConsumerState<CanteenOrdersScreen> createState() =>
      _CanteenOrdersScreenState();
}

class _CanteenOrdersScreenState extends ConsumerState<CanteenOrdersScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  Timer? _pollTimer;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 15 s so canteen sees new paid orders without manual pull-to-refresh
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        ref.read(canteenOrdersProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(canteenOrdersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh orders',
              onPressed: () =>
                  ref.read(canteenOrdersProvider.notifier).refresh(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Search by token, name, or item...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const TabBar(
                  tabs: [Tab(text: 'Active'), Tab(text: 'Completed')],
                ),
              ],
            ),
          ),
        ),
        body: asyncOrders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load orders:\n$e',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(canteenOrdersProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (orders) {
            final filtered = _query.isNotEmpty
                ? orders.where((o) {
                    final q = _query.toLowerCase();
                    return o.token.contains(q) ||
                        o.studentName.toLowerCase().contains(q) ||
                        o.items.any((i) => i.name.toLowerCase().contains(q));
                  }).toList()
                : orders;

            final active = filtered.where((o) => o.isActive).toList();
            final completed =
                filtered.where((o) => o.isCompleted).toList();

            return TabBarView(
              children: [
                _CanteenOrderList(
                    orders: active, empty: 'No active paid orders'),
                _CanteenOrderList(
                    orders: completed, empty: 'No completed orders'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CanteenOrderList extends StatelessWidget {
  final List<Order> orders;
  final String empty;
  const _CanteenOrderList({required this.orders, required this.empty});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.list_alt_outlined,
        title: empty,
        subtitle: 'Pull-to-refresh or wait for auto-refresh',
      );
    }

    return RefreshIndicator(
      onRefresh: () => Future.value(), // parent handles via provider
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _CanteenOrderCard(order: orders[i]),
      ),
    );
  }
}

class _CanteenOrderCard extends ConsumerWidget {
  final Order order;
  const _CanteenOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${order.token}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(order.studentDept,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              StatusChip(status: order.status),
            ],
          ),
          const Divider(height: 16),

          // Time
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(AppUtils.formatDateTime(order.placedAt),
                  style: theme.textTheme.bodySmall),
              if (order.isScheduled && order.scheduledFor != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.schedule_rounded,
                    size: 14, color: Color(0xFF00838F)),
                const SizedBox(width: 2),
                Text(
                  'Sched. ${AppUtils.formatTimeShort(order.scheduledFor!)}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00838F)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Items
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(item.emoji,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text('${item.name} x${item.quantity}',
                            style: theme.textTheme.bodyMedium)),
                    Text('Rs. ${item.lineTotal.toInt()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              )),

          const Divider(height: 16),
          Row(
            children: [
              const Text('Total',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
          const SizedBox(height: 12),
          _StatusActionBtn(order: order),
        ],
      ),
    );
  }
}

class _StatusActionBtn extends ConsumerWidget {
  final Order order;
  const _StatusActionBtn({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (order.status == 'Collected') {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Completed',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final (label, icon, nextStatus) = switch (order.status) {
      'Preparing' ||
      'Verified' =>
        ('Mark as Collected', Icons.check_circle_rounded, 'completed'),
      _ => ('Mark as Collected', Icons.check_circle_rounded, 'completed'),
    };

    return AppButton(
      label: label,
      icon: icon,
      onTap: () async {
        await ref
            .read(canteenOrdersProvider.notifier)
            .updateStatus(order.id, nextStatus);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Order #${order.token} marked as collected')),
          );
        }
      },
    );
  }
}
