import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:campus_eats_ag/core/l10n/canteen_language_provider.dart';
import 'package:campus_eats_ag/core/l10n/canteen_strings.dart';
import 'package:campus_eats_ag/core/services/esc_receipt_builder.dart';
import 'package:campus_eats_ag/core/services/thermal_printer_service.dart';
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

  /// Phase 11: Mark order as ready for pickup.
  /// Fires push notification to customer. Idempotent.
  Future<void> markReady(String orderId) async {
    dev.log('[CANTEEN] markReady orderId=$orderId', name: 'CanteenOrders');
    final repo = ref.read(orderRepositoryProvider);
    await repo.markReady(orderId);
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

  // ── Smart-poll state ─────────────────────────────────────────
  int _lastKnownQueueCount = -1; // -1 = initial / unknown
  String? _lastKnownOrderedAt;
  bool _showNewOrderBanner = false;
  int _newOrderDelta = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Smart adaptive poll every 8 seconds — lightweight /poll endpoint only
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) _smartPoll();
    });
    // Seed the initial count on first build
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedInitialCount());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  /// After the initial full-load, record the queue count so subsequent smart
  /// polls can detect a net-new order without a full refresh.
  void _seedInitialCount() {
    final asyncOrders = ref.read(canteenOrdersProvider);
    asyncOrders.whenData((orders) {
      final queueCount =
          orders.where((o) => !o.isPrinted && !o.isCompleted && !o.isCancelled).length;
      _lastKnownQueueCount = queueCount;
      dev.log('[POLL] seeded initial count=$queueCount', name: 'SmartPoll');
    });
  }

  /// Lightweight poll — only calls /canteen/orders/poll.
  /// If the queue count has grown → show banner + full refresh.
  /// Spam-protected: banner won't re-fire if count didn't change.
  Future<void> _smartPoll() async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      final result = await repo.pollOrderQueue();
      final newCount = result.count;
      final newOrderedAt = result.latestOrderedAt;

      dev.log(
        '[POLL] count=$newCount latestOrderedAt=$newOrderedAt (last=$_lastKnownQueueCount)',
        name: 'SmartPoll',
      );

      // Initial seed if still unknown (race condition on startup)
      if (_lastKnownQueueCount < 0) {
        _lastKnownQueueCount = newCount;
        _lastKnownOrderedAt = newOrderedAt;
        return;
      }

      // New orders arrived in queue
      final delta = newCount - _lastKnownQueueCount;
      if (delta > 0 && newOrderedAt != _lastKnownOrderedAt) {
        dev.log('[POLL] ⚡ $delta new order(s) detected — triggering full refresh', name: 'SmartPoll');
        // Full refresh to get actual order data
        await ref.read(canteenOrdersProvider.notifier).refresh();
        if (mounted) {
          setState(() {
            _showNewOrderBanner = true;
            _newOrderDelta = delta;
          });
          // Auto-dismiss banner after 4 seconds
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) setState(() => _showNewOrderBanner = false);
          });
        }
      }

      // Update tracking state
      _lastKnownQueueCount = newCount;
      _lastKnownOrderedAt = newOrderedAt;
    } catch (e) {
      dev.log('[POLL] error: $e', name: 'SmartPoll');
      // Silent fail — poll is supplementary; manual refresh always available
    }
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
    final s = ref.watch(canteenL10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.kitchenOrders, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(
              s.campusEatsCanteen,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: isDark ? s.switchToLight : s.switchToDark,
            onPressed: () => ref.read(themeProvider.notifier).toggleDark(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: s.helpAndContact,
            onPressed: _showHelp,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: s.refreshOrders,
            onPressed: () {
              setState(() => _showNewOrderBanner = false);
              ref.read(canteenOrdersProvider.notifier).refresh();
            },
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
                    hintText: s.search,
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
                tabs: [
                  Tab(text: s.tabQueue),
                  Tab(text: s.tabPrinted),
                  Tab(text: s.tabCompleted),
                ],
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // ── New Order Banner (auto-dismissing) ─────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showNewOrderBanner
                ? _NewOrderBanner(
                    delta: _newOrderDelta,
                    s: s,
                    onDismiss: () => setState(() => _showNewOrderBanner = false),
                  )
                : const SizedBox.shrink(),
          ),
          // ── Main Orders Content ─────────────────────────────────────
          Expanded(
            child: asyncOrders.when(
              loading: () => Consumer(builder: (ctx, r, _) {
                final sl = r.watch(canteenL10nProvider);
                return AppLoadingState(message: sl.loadingOrders);
              }),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      s.failedPrefix,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('$e', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(s.menuRefresh),
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
                            o.facultyName.toLowerCase().contains(q) ||
                            o.facultyRoom.toLowerCase().contains(q) ||
                            o.items.any((i) => i.name.toLowerCase().contains(q));
                      }).toList()
                    : orders;

                // ── Partition orders into three canteen buckets ──────────────
                final queueOrders = filtered
                    .where((o) => !o.isPrinted && !o.isCompleted && !o.isCancelled)
                    .toList();
                final printedOrders =
                    filtered.where((o) => o.isPrinted && !o.isCompleted).toList();
                final completedOrders =
                    filtered.where((o) => o.isCompleted).toList();

                // Update the last known queue count from the FULL (unfiltered) orders list.
                // Using the search-filtered queueOrders.length would produce a falsely-low
                // count whenever a search query is active, causing the next poll to see a
                // spurious positive delta and show a phantom "new order" banner.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _lastKnownQueueCount = orders
                      .where((o) => !o.isPrinted && !o.isCompleted && !o.isCancelled)
                      .length;
                });

                Future<void> doRefresh() =>
                    ref.read(canteenOrdersProvider.notifier).refresh();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _QueueTab(orders: queueOrders, onRefresh: doRefresh, s: s),
                    _PrintedTab(orders: printedOrders, onRefresh: doRefresh, s: s),
                    _CompletedTab(orders: completedOrders, onRefresh: doRefresh, s: s),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── New Order Banner ────────────────────────────────────────────────────

class _NewOrderBanner extends StatelessWidget {
  final int delta;
  final CanteenStrings s;
  final VoidCallback onDismiss;

  const _NewOrderBanner({
    required this.delta,
    required this.s,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final label = delta == 1
        ? s.newOrderBannerSingle
        : s.newOrderBannerMultiple(delta);
    return Material(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.92),
              AppColors.primary,
            ],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Queue Tab (Active = Prepare Now + Scheduled) ───────────────────────

class _QueueTab extends StatefulWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;
  final CanteenStrings s;
  const _QueueTab({required this.orders, required this.onRefresh, required this.s});

  @override
  State<_QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends State<_QueueTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin
    if (widget.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: EmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: widget.s.emptyQueue,
              subtitle: widget.s.emptyQueueSub,
            ),
          ),
        ),
      );
    }

    final groups = _groupOrders(widget.orders, widget.s);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
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
                s: widget.s,
              ),
              const SizedBox(height: 8),
              ...group.orders.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CanteenOrderCard(order: o, cardType: CanteenCardType.queue, s: widget.s),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  List<_OrderGroup> _groupOrders(List<Order> orders, CanteenStrings s) {
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

    prepareNow.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    for (final group in scheduledGroups.values) {
      group.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    }

    final groups = <_OrderGroup>[];

    if (prepareNow.isNotEmpty) {
      groups.add(_OrderGroup(
        label: s.prepareNow,
        orders: prepareNow,
        headerColor: AppColors.error,
        headerIcon: Icons.flash_on_rounded,
      ));
    }

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

class _PrintedTab extends StatefulWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;
  final CanteenStrings s;
  const _PrintedTab({required this.orders, required this.onRefresh, required this.s});

  @override
  State<_PrintedTab> createState() => _PrintedTabState();
}

class _PrintedTabState extends State<_PrintedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: EmptyState(
              icon: Icons.print_rounded,
              title: widget.s.emptyPrinted,
              subtitle: widget.s.emptyPrintedSub,
            ),
          ),
        ),
      );
    }

    final sorted = [...widget.orders]..sort((a, b) =>
        (b.printedAt ?? b.placedAt).compareTo(a.printedAt ?? a.placedAt));

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) =>
            _CanteenOrderCard(order: sorted[i], cardType: CanteenCardType.printed, s: widget.s),
      ),
    );
  }
}

// ─── Completed Tab ───────────────────────────────────────────────────────

class _CompletedTab extends StatefulWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;
  final CanteenStrings s;
  const _CompletedTab({required this.orders, required this.onRefresh, required this.s});

  @override
  State<_CompletedTab> createState() => _CompletedTabState();
}

class _CompletedTabState extends State<_CompletedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: widget.s.emptyCompleted,
              subtitle: widget.s.emptyCompletedSub,
            ),
          ),
        ),
      );
    }

    final sorted = [...widget.orders]..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) =>
            _CanteenOrderCard(order: sorted[i], cardType: CanteenCardType.completed, s: widget.s),
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
  final CanteenStrings s;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.s,
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
          s.orderCount(count),
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
  final CanteenStrings s;
  const _CanteenOrderCard({required this.order, required this.cardType, required this.s});

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
                    Row(
                      children: [
                        if (order.customerRole == 'faculty') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              s.faculty,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          if (order.facultyRoom.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.meeting_room_outlined,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text(
                              order.facultyRoom,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ] else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.student,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (cardType == CanteenCardType.printed)
                const _StateChip(label: 'PRINTED', color: AppColors.warning, icon: Icons.print_rounded)
              else if (cardType == CanteenCardType.completed)
                const _StateChip(label: 'DONE', color: AppColors.success, icon: Icons.check_circle_rounded)
              else if (order.isScheduled)
                const _StateChip(label: 'SCHEDULED', color: AppColors.statusScheduled, icon: Icons.schedule_rounded),
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
                  s.pickupAt(AppUtils.formatTimeShort(order.scheduledFor!)),
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
                child: Text(
                  s.paid,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ),
              const Spacer(),
              _CardAction(
                label: s.openSlip,
                icon: Icons.receipt_long_rounded,
                onTap: () => _openSlip(context, ref),
              ),
            ],
          ),

          // ── Phase 11: Mark Ready button (queue cards only) ───────
          if (cardType == CanteenCardType.queue) ...[
            const SizedBox(height: 10),
            order.isReady
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 15, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          s.orderReady,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: _MarkReadyButton(orderId: order.id, s: s),
                  ),
          ],
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
        onDirectPrint: cardType == CanteenCardType.queue
            ? () async {
                Navigator.pop(ctx);
                await _doPrintDirect(context, ref);
              }
            : null,
        onFallbackPrint: cardType == CanteenCardType.queue
            ? () async {
                Navigator.pop(ctx);
                await _doPrintFallback(context, ref);
              }
            : null,
      ),
    );
  }

  /// Phase 11 Print Semantics (hardened):
  ///   1. Attempt direct ESC/POS thermal print (if printer paired)
  ///   2. On ESC/POS success → commit printedAt on backend
  ///   3. On ESC/POS failure or no printer → show explicit warning,
  ///      DO NOT silently commit printedAt — staff must use explicit fallback
  ///
  /// This is called from the "🖨 Direct Thermal Print" button in the slip sheet.
  Future<void> _doPrintDirect(BuildContext context, WidgetRef ref) async {
    final thermalSvc = ThermalPrinterService.instance;
    final sl = ref.read(canteenL10nProvider);

    // ── If no printer paired, immediately route to fallback ─────────────────
    if (!thermalSvc.hasPrinter) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sl.thermalDisconnected),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: sl.fallbackPrint,
              onPressed: () => _doPrintFallback(context, ref),
            ),
          ),
        );
      }
      return;
    }

    // ── Build ESC/POS ticket ─────────────────────────────────────────────────
    final ticket = await EscReceiptBuilder.buildTicket(order);
    if (ticket == null) {
      dev.log('[PRINT] ESC receipt build failed', name: 'PrintSlip');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sl.thermalNotFound),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: sl.fallbackPrint,
              onPressed: () => _doPrintFallback(context, ref),
            ),
          ),
        );
      }
      return;
    }

    // ── Attempt direct thermal print ─────────────────────────────────────────
    dev.log('[PRINT] Attempting direct thermal print…', name: 'PrintSlip');
    final result = await thermalSvc.printTicket(ticket);

    if (result == ThermalPrintResult.success) {
      // Physical output confirmed → NOW safe to commit printedAt
      try {
        await ref.read(canteenOrdersProvider.notifier).printOrder(order.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sl.printDirect),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        // Backend commit failed after physical print — show warn, not error
        dev.log('[PRINT] Backend printOrder failed after direct print: $e', name: 'PrintSlip');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${sl.printDirect} (${sl.printBackendFailed}: $e)'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } else {
      // Thermal print failed — DO NOT commit printedAt — offer fallback
      dev.log('[PRINT] Direct thermal failed: $result', name: 'PrintSlip');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sl.thermalNotFound),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: sl.fallbackPrint,
              onPressed: () => _doPrintFallback(context, ref),
            ),
          ),
        );
      }
    }
  }

  /// Phase 11: System/PDF fallback print.
  /// Staff explicitly chooses this path (or it's shown when thermal is unavailable).
  /// printedAt is committed only AFTER the system print dialog confirms output.
  Future<void> _doPrintFallback(BuildContext context, WidgetRef ref) async {
    final sl = ref.read(canteenL10nProvider);
    dev.log('[PRINT] Fallback PDF print: order ${order.id}', name: 'PrintSlip');
    try {
      final pdfBytes = await _buildSlipPdf(order).save();
      final printed = await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'CampusEats_Token_${order.token}',
      );

      if (!printed) {
        // Dialog dismissed without printing — DO NOT commit printedAt
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Print cancelled — order NOT marked as printed.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // PDF printed → commit printedAt on backend
      await ref.read(canteenOrdersProvider.notifier).printOrder(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sl.printFallbackSuccess),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      dev.log('[PRINT] Fallback print error: $e', name: 'PrintSlip');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${sl.printBackendFailed}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Builds a thermal-style PDF slip for the order.
  pw.Document _buildSlipPdf(Order order) {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm, // 80mm wide — standard thermal roll
          double.infinity,
          marginAll: 6 * PdfPageFormat.mm,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'CAMPUS EATS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 6),
              pw.Text(
                '#${order.token}',
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                order.customerRole == 'faculty' ? 'FACULTY ORDER' : 'STUDENT ORDER',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
              _pdfRow('Name', order.studentName),
              if (order.customerRole == 'faculty') ...[
                if (order.facultyDept.isNotEmpty) _pdfRow('Dept', order.facultyDept),
                if (order.facultyRoom.isNotEmpty) _pdfRow('Room', order.facultyRoom),
              ],
              _pdfRow('Ordered', AppUtils.formatDateTime(order.placedAt)),
              if (order.isScheduled && order.scheduledFor != null)
                _pdfRow('Pickup', AppUtils.formatTimeShort(order.scheduledFor!))
              else if (order.estimatedReadyAt != null)
                _pdfRow('Ready By', AppUtils.formatTimeShort(order.estimatedReadyAt!)),
              _pdfRow('Payment', 'PAID • UPI/Razorpay'),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'ORDER ITEMS',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              ...order.items.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            item.name,
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Text(
                          '×${item.quantity}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          'Rs.${item.lineTotal.toInt()}',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Rs. ${order.total.toInt()}',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
              pw.Text(
                'Thank you! Visit CampusEats again.',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    return doc;
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
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

// ─── Mark Ready Button (Phase 11) ────────────────────────────────────────────
//
// Standalone ConsumerStatefulWidget so it can access the notifier and
// show a SnackBar without prop-drilling WidgetRef or BuildContext up.

class _MarkReadyButton extends ConsumerStatefulWidget {
  final String orderId;
  final CanteenStrings s;
  const _MarkReadyButton({required this.orderId, required this.s});

  @override
  ConsumerState<_MarkReadyButton> createState() => _MarkReadyButtonState();
}

class _MarkReadyButtonState extends ConsumerState<_MarkReadyButton> {
  bool _loading = false;

  Future<void> _onTap() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(canteenOrdersProvider.notifier)
          .markReady(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.s.markedReady),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.s.failedMsg}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: _loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.notifications_active_rounded, size: 16),
      label: Text(
        widget.s.markReady,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

// ─── Canteen Slip Bottom Sheet ────────────────────────────────────────────

class CanteenSlipBottomSheet extends StatelessWidget {
  final Order order;
  final CanteenCardType cardType;
  /// Direct ESC/POS thermal print (Phase 11).
  final Future<void> Function()? onDirectPrint;
  /// System/PDF fallback print (Phase 10, always available).
  final Future<void> Function()? onFallbackPrint;

  const CanteenSlipBottomSheet({
    super.key,
    required this.order,
    required this.cardType,
    this.onDirectPrint,
    this.onFallbackPrint,
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
                  Consumer(builder: (ctx2, ref2, _) {
                    final sl = ref2.watch(canteenL10nProvider);
                    return Column(
                      children: [
                        Text(
                          sl.campusEats,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 3.0,
                          ),
                        ),
                        const SizedBox(height: 6),
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
                        if (cardType == CanteenCardType.printed)
                          _StatusPill(sl.slipPrinted, AppColors.warning, Icons.print_rounded)
                        else if (cardType == CanteenCardType.completed)
                          _StatusPill(sl.slipCollected, AppColors.success, Icons.check_circle_rounded)
                        else
                          _StatusPill(sl.slipActive, AppColors.primary, Icons.flash_on_rounded),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),
                  const DottedDivider(),
                  const SizedBox(height: 16),

                  Consumer(builder: (ctx2, ref2, _) {
                    final sl = ref2.watch(canteenL10nProvider);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SlipRow(sl.slipName, order.studentName),
                        const SizedBox(height: 8),
                        _SlipRow(
                          sl.slipRole,
                          order.customerRole == 'faculty' ? sl.slipRoleFaculty : sl.slipRoleStudent,
                        ),
                        if (order.customerRole == 'faculty') ...[
                          if (order.facultyDept.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _SlipRow(sl.slipDept, order.facultyDept),
                          ],
                          if (order.facultyRoom.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _SlipRow(sl.slipRoom, order.facultyRoom,
                                highlight: true,
                                highlightColor: AppColors.warning),
                          ],
                        ],
                        const SizedBox(height: 8),
                        _SlipRow(sl.slipOrdered, AppUtils.formatDateTime(order.placedAt)),
                        if (order.isScheduled && order.scheduledFor != null) ...[
                          const SizedBox(height: 8),
                          _SlipRow(
                            sl.slipPickupTime,
                            AppUtils.formatTimeShort(order.scheduledFor!),
                            highlight: true,
                            highlightColor: AppColors.statusScheduled,
                          ),
                        ] else if (order.estimatedReadyAt != null) ...[
                          const SizedBox(height: 8),
                          _SlipRow(
                            sl.slipReadyBy,
                            AppUtils.formatTimeShort(order.estimatedReadyAt!),
                            highlight: true,
                            highlightColor: AppColors.warning,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _SlipRow(sl.slipPayment, sl.slipPaidLabel,
                            highlight: true, highlightColor: AppColors.success),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),
                  const DottedDivider(),
                  const SizedBox(height: 16),

                  Consumer(builder: (ctx2, ref2, _) {
                    final sl = ref2.watch(canteenL10nProvider);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        sl.slipOrderItems,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  }),
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
                  const DottedDivider(),
                  const SizedBox(height: 12),

                  Consumer(builder: (ctx2, ref2, _) {
                    final sl = ref2.watch(canteenL10nProvider);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sl.slipTotal,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
                        Text(
                          'Rs. ${order.total.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 24),

                  // ── Action buttons ───────────────────────────────
                  Consumer(builder: (ctx2, ref2, _) {
                    final sl = ref2.watch(canteenL10nProvider);
                    return Column(
                      children: [
                        // ── Phase 11: Direct thermal print (primary) ──────────
                        if (onDirectPrint != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.print_rounded),
                              label: Text(
                                ThermalPrinterService.instance.hasPrinter
                                    ? sl.directPrint
                                    : sl.fallbackPrint,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: onDirectPrint,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        // ── Phase 10/11: System/PDF fallback (always visible) ─
                        if (onFallbackPrint != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                              label: Text(sl.fallbackPrint),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: onFallbackPrint,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: Text(sl.copyTokenLabel(order.token)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: order.token));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(sl.tokenCopied(order.token)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(sl.slipClose),
                        ),
                      ],
                    );
                  }),
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

// DottedDivider is now in shared_widgets.dart (exported as DottedDivider)
