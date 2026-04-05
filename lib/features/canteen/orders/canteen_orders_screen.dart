import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/models/order.dart';

// ─── Provider — always fetches live from backend ──────────────────────────
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
    dev.log(
      '[CANTEEN] updateStatus orderId=$orderId status=$newStatus',
      name: 'CanteenOrders',
    );
    final repo = ref.read(orderRepositoryProvider);
    await repo.updateStatus(orderId, newStatus);
    await refresh();
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────

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
    // Auto-refresh every 15 s — canteen always sees new paid orders
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) ref.read(canteenOrdersProvider.notifier).refresh();
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
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setState(() => _query = q),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(canteenOrdersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kitchen Orders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh orders',
              onPressed: () => ref.read(canteenOrdersProvider.notifier).refresh(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
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
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
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
            final completed = filtered.where((o) => o.isCompleted).toList();

            Future<void> doRefresh() =>
                ref.read(canteenOrdersProvider.notifier).refresh();

            return TabBarView(
              children: [
                _ActiveOrderList(orders: active, onRefresh: doRefresh),
                _CompletedOrderList(orders: completed, onRefresh: doRefresh),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Active Orders — Time-Grouped ───────────────────────────────────────

class _ActiveOrderList extends StatelessWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;
  const _ActiveOrderList({required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: EmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: 'No active orders',
              subtitle: 'New paid orders appear here — pull to refresh',
            ),
          ),
        ),
      );
    }

    // Group orders into time buckets
    final groups = _groupOrders(orders);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: groups.length,
        itemBuilder: (ctx, i) {
          final group = groups[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: group.headerColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: group.headerColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(group.headerIcon,
                              size: 14, color: group.headerColor),
                          const SizedBox(width: 6),
                          Text(
                            group.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: group.headerColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${group.orders.length} order${group.orders.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ...group.orders.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CanteenOrderCard(order: o, isActive: true),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_OrderGroup> _groupOrders(List<Order> orders) {
    final now = DateTime.now();
    final nowGroup = <Order>[];
    final scheduledGroups = <String, List<Order>>{};

    for (final order in orders) {
      if (order.isScheduled && order.scheduledFor != null) {
        // Round to nearest 30-minute slot for grouping key.
        // scheduledFor is already .toLocal() — so hour/minute are IST-correct.
        final sf = order.scheduledFor!;
        final slotMinute = sf.minute < 30 ? 0 : 30;
        final slot = DateTime(sf.year, sf.month, sf.day, sf.hour, slotMinute);
        // Format as 12-hour label, e.g. "11:30 AM" or "12:00 PM"
        final hour12 = slot.hour == 0
            ? 12
            : (slot.hour > 12 ? slot.hour - 12 : slot.hour);
        final amPm = slot.hour < 12 ? 'AM' : 'PM';
        final label =
            '${hour12.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')} $amPm';
        scheduledGroups.putIfAbsent(label, () => []).add(order);
      } else {
        nowGroup.add(order);
      }
    }

    final groups = <_OrderGroup>[];

    if (nowGroup.isNotEmpty) {
      groups.add(_OrderGroup(
        label: 'Prepare Now',
        orders: nowGroup,
        headerColor: AppColors.error,
        headerIcon: Icons.flash_on_rounded,
        sortKey: now,
      ));
    }

    final sortedSlots = scheduledGroups.keys.toList()..sort();
    for (final slot in sortedSlots) {
      groups.add(_OrderGroup(
        label: slot,
        orders: scheduledGroups[slot]!,
        headerColor: AppColors.primary,
        headerIcon: Icons.schedule_rounded,
        sortKey: DateTime.now(),
      ));
    }

    return groups;
  }
}

class _OrderGroup {
  final String label;
  final List<Order> orders;
  final Color headerColor;
  final IconData headerIcon;
  final DateTime sortKey;

  const _OrderGroup({
    required this.label,
    required this.orders,
    required this.headerColor,
    required this.headerIcon,
    required this.sortKey,
  });
}

// ─── Completed Orders List ───────────────────────────────────────────────

class _CompletedOrderList extends StatelessWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;
  const _CompletedOrderList({required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'No completed orders',
              subtitle: 'Verified orders appear here',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) =>
            _CanteenOrderCard(order: orders[i], isActive: false),
      ),
    );
  }
}

// ─── Order Card ──────────────────────────────────────────────────────────

class _CanteenOrderCard extends StatelessWidget {
  final Order order;
  final bool isActive;
  const _CanteenOrderCard({required this.order, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: token, name, status
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
                    Text(
                      order.studentName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
              StatusChip(status: order.status),
            ],
          ),

          const Divider(height: 16),

          // Time + ETA
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(AppUtils.formatDateTime(order.placedAt),
                  style: theme.textTheme.bodySmall),
              if (order.isScheduled && order.scheduledFor != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.schedule_rounded,
                    size: 14, color: Color(0xFF00838F)),
                const SizedBox(width: 2),
                Text(
                  'Pickup ${AppUtils.formatTimeShort(order.scheduledFor!)}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00838F)),
                ),
              ] else if (order.estimatedReadyAt != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.timer_outlined,
                    size: 14, color: Color(0xFFFF9800)),
                const SizedBox(width: 2),
                Text(
                  order.etaLabel ?? '',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF9800)),
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
                    Text(item.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${item.name} x${item.quantity}',
                          style: theme.textTheme.bodyMedium),
                    ),
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
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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

          // CTA: active orders show a "Verify to complete" hint — no standalone complete button
          if (isActive) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.25)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      size: 16, color: AppColors.info),
                  SizedBox(width: 8),
                  Text(
                    'Go to Verify tab to complete via QR scan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              child: const Text(
                '✓ Collected & Completed',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
