import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/data/repositories/theme_repository.dart';
import 'package:campus_eats_ag/models/order.dart';
import 'canteen_help_bottom_sheet.dart';

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

  Future<void> printOrder(String orderId) async {
    dev.log('[CANTEEN] printOrder orderId=$orderId', name: 'CanteenOrders');
    final repo = ref.read(orderRepositoryProvider);
    await repo.printOrder(orderId);
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

class _CanteenOrdersScreenState extends ConsumerState<CanteenOrdersScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  Timer? _pollTimer;
  String _query = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Auto-refresh every 15 s
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) ref.read(canteenOrdersProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setState(() => _query = q),
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const CanteenHelpBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(canteenOrdersProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == 2;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kitchen Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(
              'CampusEats Canteen',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          // Dark mode toggle — 1-tap from home screen (Phase 3 requirement)
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () =>
                ref.read(themeProvider.notifier).toggleDark(),
          ),
          // Help / Contact — 1-tap from home screen
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Help & Contact',
            onPressed: _showHelp,
          ),
          // Manual refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh orders',
            onPressed: () => ref.read(canteenOrdersProvider.notifier).refresh(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search token, name, or item…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
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
                    filled: true,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Queue'),
                  Tab(text: 'Printed'),
                  Tab(text: 'Completed'),
                ],
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
              const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Could not load orders',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text('$e', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                onPressed: () =>
                    ref.read(canteenOrdersProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        data: (orders) {
          // Apply search filter
          final filtered = _query.isNotEmpty
              ? orders.where((o) {
                  final q = _query.toLowerCase();
                  return o.token.contains(q) ||
                      o.studentName.toLowerCase().contains(q) ||
                      o.items.any((i) => i.name.toLowerCase().contains(q));
                }).toList()
              : orders;

          // ── Partition orders into three buckets ──────────────────
          // Queue  = paid + not printed + not completed (active)
          // Printed = has printedAt timestamp (status still 'Verified')
          // Completed = Collected (completed)
          final queueOrders = filtered.where((o) => o.isActive).toList();
          final printedOrders = filtered.where((o) => o.isPrinted && !o.isCompleted).toList();
          final completedOrders = filtered.where((o) => o.isCompleted).toList();

          Future<void> doRefresh() =>
              ref.read(canteenOrdersProvider.notifier).refresh();

          return TabBarView(
            controller: _tabController,
            children: [
              _QueueTab(orders: queueOrders, onRefresh: doRefresh),
              _PrintedTab(orders: printedOrders, onRefresh: doRefresh),
              _CompletedTab(orders: completedOrders, onRefresh: doRefresh),
            ],
          );
        },
      ),
    );
  }
}


// ─── Queue Tab (Active = Prepare Now + Scheduled) ───────────────────────

class _QueueTab extends StatelessWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;
  const _QueueTab({required this.orders, required this.onRefresh});

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
              title: 'Queue is clear!',
              subtitle: 'New paid orders appear here — pull to refresh',
            ),
          ),
        ),
      );
    }

    final groups = _groupOrders(orders);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: groups.length,
        itemBuilder: (ctx, i) {
          final group = groups[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                label: group.label,
                count: group.orders.length,
                color: group.headerColor,
                icon: group.headerIcon,
              ),
              const SizedBox(height: 8),
              ...group.orders.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CanteenOrderCard(order: o, cardType: CanteenCardType.queue),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  List<_OrderGroup> _groupOrders(List<Order> orders) {
    final prepareNow = <Order>[];
    final scheduledGroups = <String, List<Order>>{};

    for (final order in orders) {
      if (order.isScheduled && order.scheduledFor != null) {
        final sf = order.scheduledFor!;
        final slotMinute = sf.minute < 30 ? 0 : 30;
        final slot = DateTime(sf.year, sf.month, sf.day, sf.hour, slotMinute);
        final hour12 = slot.hour == 0
            ? 12
            : (slot.hour > 12 ? slot.hour - 12 : slot.hour);
        final amPm = slot.hour < 12 ? 'AM' : 'PM';
        final label =
            '${hour12.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')} $amPm';
        scheduledGroups.putIfAbsent(label, () => []).add(order);
      } else {
        prepareNow.add(order);
      }
    }

    // ── Sort: newest orders at the top within each bucket ────────────────
    prepareNow.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    for (final group in scheduledGroups.values) {
      group.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    }

    final groups = <_OrderGroup>[];

    if (prepareNow.isNotEmpty) {
      groups.add(_OrderGroup(
        label: 'Prepare Now',
        orders: prepareNow,
        headerColor: AppColors.error,
        headerIcon: Icons.flash_on_rounded,
      ));
    }

    // Scheduled slots sorted by time label (lexicographic = chronological for HH:MM AM/PM)
    final sortedSlots = scheduledGroups.keys.toList()..sort();
    for (final slot in sortedSlots) {
      groups.add(_OrderGroup(
        label: slot,
        orders: scheduledGroups[slot]!,
        headerColor: AppColors.statusScheduled,
        headerIcon: Icons.schedule_rounded,
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

  const _OrderGroup({
    required this.label,
    required this.orders,
    required this.headerColor,
    required this.headerIcon,
  });
}

// ─── Printed Tab ─────────────────────────────────────────────────────────

class _PrintedTab extends StatelessWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;
  const _PrintedTab({required this.orders, required this.onRefresh});

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
              icon: Icons.print_rounded,
              title: 'No printed orders',
              subtitle: 'When you print a slip, the order moves here',
            ),
          ),
        ),
      );
    }

    // Newest printed first
    final sorted = [...orders]..sort((a, b) =>
        (b.printedAt ?? b.placedAt).compareTo(a.printedAt ?? a.placedAt));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) =>
            _CanteenOrderCard(order: sorted[i], cardType: CanteenCardType.printed),
      ),
    );
  }
}

// ─── Completed Tab ───────────────────────────────────────────────────────

class _CompletedTab extends StatelessWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;
  const _CompletedTab({required this.orders, required this.onRefresh});

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
              subtitle: 'Verified and collected orders appear here',
            ),
          ),
        ),
      );
    }

    // Newest completed first
    final sorted = [...orders]..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) =>
            _CanteenOrderCard(order: sorted[i], cardType: CanteenCardType.completed),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count order${count == 1 ? '' : 's'}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─── Card Type Enum ──────────────────────────────────────────────────────

enum CanteenCardType { queue, printed, completed }

// ─── Order Card ──────────────────────────────────────────────────────────

class _CanteenOrderCard extends ConsumerWidget {
  final Order order;
  final CanteenCardType cardType;
  const _CanteenOrderCard({required this.order, required this.cardType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      onTap: () => _openSlip(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large token badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _tokenColor(cardType).withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _tokenColor(cardType).withValues(alpha: isDark ? 0.5 : 0.3),
                  ),
                ),
                child: Text(
                  '#${order.token}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _tokenColor(cardType),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      order.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Role chip (Student / Faculty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Student', // Future: derive from studentDept/role field
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // State chip on the right
              if (cardType == CanteenCardType.printed)
                _StateChip(label: 'PRINTED', color: AppColors.warning, icon: Icons.print_rounded)
              else if (cardType == CanteenCardType.completed)
                _StateChip(label: 'DONE', color: AppColors.success, icon: Icons.check_circle_rounded)
              else if (order.isScheduled)
                _StateChip(label: 'SCHEDULED', color: AppColors.statusScheduled, icon: Icons.schedule_rounded),
            ],
          ),

          const SizedBox(height: 12),

          // ── Time row ────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 13, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                AppUtils.formatDateTime(order.placedAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),

          // ETA / Scheduled time
          if (order.isScheduled && order.scheduledFor != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.flag_rounded, size: 13, color: AppColors.statusScheduled),
                const SizedBox(width: 4),
                Text(
                  'Pickup at ${AppUtils.formatTimeShort(order.scheduledFor!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusScheduled,
                  ),
                ),
              ],
            ),
          ] else if (order.estimatedReadyAt != null && cardType == CanteenCardType.queue) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 13, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  order.etaLabel ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // ── Items summary ────────────────────────────────────────
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    if (item.emoji.isNotEmpty) ...[
                      Text(item.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '×${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Rs. ${item.lineTotal.toInt()}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              )),

          const Divider(height: 20),

          // ── Total + CTA row ──────────────────────────────────────
          Row(
            children: [
              Text(
                'Rs. ${order.total.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ),
              const Spacer(),
              // Primary action button
              _CardAction(
                label: 'Open Slip',
                icon: Icons.receipt_long_rounded,
                onTap: () => _openSlip(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _tokenColor(CanteenCardType type) {
    switch (type) {
      case CanteenCardType.queue:
        return AppColors.primary;
      case CanteenCardType.printed:
        return AppColors.warning;
      case CanteenCardType.completed:
        return AppColors.success;
    }
  }

  void _openSlip(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => CanteenSlipBottomSheet(
        order: order,
        cardType: cardType,
        onMarkPrinted: cardType == CanteenCardType.queue
            ? () async {
                Navigator.pop(ctx);
                await ref
                    .read(canteenOrdersProvider.notifier)
                    .printOrder(order.id);
              }
            : null,
      ),
    );
  }
}

// ─── Small Chips ─────────────────────────────────────────────────────────

class _StateChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StateChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CardAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Canteen Slip Bottom Sheet ────────────────────────────────────────────

class CanteenSlipBottomSheet extends StatelessWidget {
  final Order order;
  final CanteenCardType cardType;
  final Future<void> Function()? onMarkPrinted;

  const CanteenSlipBottomSheet({
    super.key,
    required this.order,
    required this.cardType,
    this.onMarkPrinted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Slip header ─────────────────────────────────
                  Text(
                    'CAMPUS EATS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Large token display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '#${order.token}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status badge
                  if (cardType == CanteenCardType.printed)
                    _StatusPill('PRINTED', AppColors.warning, Icons.print_rounded)
                  else if (cardType == CanteenCardType.completed)
                    _StatusPill('COLLECTED', AppColors.success, Icons.check_circle_rounded)
                  else
                    _StatusPill('ACTIVE', AppColors.primary, Icons.flash_on_rounded),

                  const SizedBox(height: 20),
                  const _DottedDivider(),
                  const SizedBox(height: 16),

                  // ── Customer details ─────────────────────────────
                  _SlipRow('Name', order.studentName),
                  const SizedBox(height: 8),
                  _SlipRow('Role', 'Student'),
                  const SizedBox(height: 8),
                  _SlipRow('Ordered', AppUtils.formatDateTime(order.placedAt)),
                  if (order.isScheduled && order.scheduledFor != null) ...[
                    const SizedBox(height: 8),
                    _SlipRow(
                      'Pickup Time',
                      AppUtils.formatTimeShort(order.scheduledFor!),
                      highlight: true,
                      highlightColor: AppColors.statusScheduled,
                    ),
                  ] else if (order.estimatedReadyAt != null) ...[
                    const SizedBox(height: 8),
                    _SlipRow(
                      'Ready By (ETA)',
                      AppUtils.formatTimeShort(order.estimatedReadyAt!),
                      highlight: true,
                      highlightColor: AppColors.warning,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _SlipRow('Payment', 'PAID • UPI / Razorpay',
                      highlight: true, highlightColor: AppColors.success),

                  const SizedBox(height: 16),
                  const _DottedDivider(),
                  const SizedBox(height: 16),

                  // ── Items ────────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ORDER ITEMS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            if (item.emoji.isNotEmpty) ...[
                              Text(item.emoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            Text(
                              '×${item.quantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Rs. ${item.lineTotal.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 12),
                  const _DottedDivider(),
                  const SizedBox(height: 12),

                  // ── Total ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
                      Text(
                        'Rs. ${order.total.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Action buttons ───────────────────────────────
                  if (onMarkPrinted != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('Mark as Printed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: onMarkPrinted,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Copy token for quick reference
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text('Copy Token #${order.token}'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.token));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Token #${order.token} copied'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusPill(this.label, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1,
              )),
        ],
      ),
    );
  }
}

class _SlipRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;

  const _SlipRow(this.label, this.value,
      {this.highlight = false, this.highlightColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = highlight ? highlightColor : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, bc) {
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      final count = (bc.maxWidth / (dashWidth + dashSpace)).floor();
      final color = Theme.of(context).colorScheme.outlineVariant;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          count,
          (_) => Container(
            width: dashWidth,
            height: 1,
            color: color,
          ),
        ),
      );
    });
  }
}

