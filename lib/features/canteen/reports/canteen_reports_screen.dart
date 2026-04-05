import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:intl/intl.dart';

// ─── Provider: fetch real reports from backend ─────────────────────────
final canteenReportsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  dev.log('[REPORTS] Fetching from backend...', name: 'Reports');
  final repo = ref.read(orderRepositoryProvider);
  final data = await repo.getReports();
  if (data == null) throw Exception('Failed to load reports');
  dev.log('[REPORTS] OK: ${data.keys.join(', ')}', name: 'Reports');
  return data;
});

class CanteenReportsScreen extends ConsumerWidget {
  const CanteenReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReports = ref.watch(canteenReportsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh reports',
            onPressed: () => ref.invalidate(canteenReportsProvider),
          ),
        ],
      ),
      body: asyncReports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart_rounded, size: 52, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Could not load reports\n$e',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(canteenReportsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final today = data['today'] as Map<String, dynamic>? ?? {};
          final month = data['thisMonth'] as Map<String, dynamic>? ?? {};
          final topItemsRaw = data['topItems'] as List? ?? [];
          final topItems = topItemsRaw
              .map((e) => e as Map<String, dynamic>)
              .toList();

          final todayCount = today['orderCount'] as int? ?? 0;
          final todayRevenue = (today['revenue'] as num?)?.toDouble() ?? 0.0;
          final monthCount = month['orderCount'] as int? ?? 0;
          final monthRevenue =
              (month['revenue'] as num?)?.toDouble() ?? 0.0;
          final avgDaily =
              (month['avgDailyOrders'] as num?)?.toDouble() ?? 0.0;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(canteenReportsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Today ──────────────────────────────────────
                  Text(
                    'Today — ${DateFormat('EEEE, d MMM').format(DateTime.now())}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          icon: Icons.receipt_long_rounded,
                          label: "Today's Orders",
                          value: '$todayCount',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          icon: Icons.currency_rupee_rounded,
                          label: "Today's Revenue",
                          value: 'Rs. ${todayRevenue.toInt()}',
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── This Month ─────────────────────────────────
                  Text(
                    'This Month',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.bar_chart_rounded,
                                  color: theme.colorScheme.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMMM yyyy').format(DateTime.now()),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs. ${monthRevenue.toInt()}',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '$monthCount orders · avg ${avgDaily.toStringAsFixed(1)}/day',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Top Items ──────────────────────────────────
                  Text(
                    'Top Ordered Items',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  if (topItems.isEmpty)
                    AppCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No sales data yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    )
                  else
                    AppCard(
                      child: Column(
                        children:
                            topItems.asMap().entries.map((e) {
                          final rank = e.key + 1;
                          final item = e.value;
                          final name =
                              item['name'] as String? ?? '—';
                          final qty =
                              item['totalQuantity'] as int? ?? 0;

                          final rankColor = rank == 1
                              ? const Color(0xFFFFC107)
                              : rank == 2
                                  ? const Color(0xFFBDBDBD)
                                  : rank == 3
                                      ? const Color(0xFFCD7F32)
                                      : theme.colorScheme
                                          .surfaceContainerHighest;
                          final rankTextColor = rank <= 3
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant;

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 9),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: rankColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$rank',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: rankTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'x$qty',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
