import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/data/repositories/settings_repository.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _loading = false;
  CanteenOperationalStatus? _status;
  String? _error;

  // Status message editing
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final s = await repo.getCanteenStatus();
      if (mounted) {
        setState(() {
          _status = s;
          _msgCtrl.text = s.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _setStatus(CanteenStatus status) async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final updated = await repo.setCanteenStatus(
        status: status,
        message: _msgCtrl.text.trim(),
      );
      if (mounted) {
        setState(() { _status = updated; _loading = false; });
        _showSnack(
          'Canteen set to ${updated.statusLabel}',
          _statusColor(updated.status),
        );
        // Invalidate the public status provider so customer screens auto-refresh
        ref.invalidate(canteenStatusProvider);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Color _statusColor(CanteenStatus s) {
    switch (s) {
      case CanteenStatus.open:
        return AppColors.success;
      case CanteenStatus.paused:
        return AppColors.warning;
      case CanteenStatus.closed:
        return AppColors.error;
    }
  }

  IconData _statusIcon(CanteenStatus s) {
    switch (s) {
      case CanteenStatus.open:
        return Icons.store_rounded;
      case CanteenStatus.paused:
        return Icons.pause_circle_rounded;
      case CanteenStatus.closed:
        return Icons.store_mall_directory_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.read(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              'CampusEats Management',
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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh status',
            onPressed: _loadStatus,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Admin greeting ────────────────────────────────────────────
              AppCard(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.name ?? 'Admin'}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Error ─────────────────────────────────────────────────────
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              // ── Canteen Operational Status Card ───────────────────────────
              Text(
                'Canteen Status',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),

              if (_loading && _status == null)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ))
              else
                _StatusCard(
                  status: _status,
                  loading: _loading,
                  statusColor: _status != null
                      ? _statusColor(_status!.status)
                      : Colors.grey,
                  statusIcon: _status != null
                      ? _statusIcon(_status!.status)
                      : Icons.store_rounded,
                  onSetOpen: () => _setStatus(CanteenStatus.open),
                  onSetPaused: () => _setStatus(CanteenStatus.paused),
                  onSetClosed: () => _setStatus(CanteenStatus.closed),
                  msgCtrl: _msgCtrl,
                ),

              const SizedBox(height: 24),

              // ── Quick Actions ──────────────────────────────────────────────
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),

              AppCard(
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Manage Menu Availability',
                      subtitle: 'Mark items unavailable today / special',
                      color: AppColors.primary,
                      onTap: () => context.go('/admin/menu'),
                    ),
                    const Divider(height: 16),
                    _ActionTile(
                      icon: Icons.people_rounded,
                      label: 'Staff Accounts',
                      subtitle: 'Enable / disable canteen staff access',
                      color: AppColors.warning,
                      onTap: () => context.go('/admin/staff'),
                    ),
                    const Divider(height: 16),
                    _ActionTile(
                      icon: Icons.bar_chart_rounded,
                      label: 'View Today\'s Reports',
                      subtitle: 'Check sales and order totals',
                      color: AppColors.success,
                      onTap: () {
                        _showSnack('Reports available in Canteen view', Colors.blueGrey);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Card ─────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final CanteenOperationalStatus? status;
  final bool loading;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onSetOpen;
  final VoidCallback onSetPaused;
  final VoidCallback onSetClosed;
  final TextEditingController msgCtrl;

  const _StatusCard({
    required this.status,
    required this.loading,
    required this.statusColor,
    required this.statusIcon,
    required this.onSetOpen,
    required this.onSetPaused,
    required this.onSetClosed,
    required this.msgCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current status header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currently: ${status?.statusLabel ?? '—'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: statusColor,
                      ),
                    ),
                    if (status?.message.isNotEmpty == true)
                      Text(
                        status!.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Message field
          TextField(
            controller: msgCtrl,
            maxLength: 120,
            decoration: InputDecoration(
              hintText: 'Optional notice for customers (e.g. "Back in 10 min")',
              labelText: 'Status Message',
              prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              counterText: '',
            ),
          ),

          const SizedBox(height: 16),

          // Status action buttons
          Row(
            children: [
              Expanded(
                child: _StatusButton(
                  label: 'Open',
                  icon: Icons.store_rounded,
                  color: AppColors.success,
                  selected: status?.status == CanteenStatus.open,
                  onTap: loading ? null : onSetOpen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusButton(
                  label: 'Paused',
                  icon: Icons.pause_circle_rounded,
                  color: AppColors.warning,
                  selected: status?.status == CanteenStatus.paused,
                  onTap: loading ? null : onSetPaused,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusButton(
                  label: 'Closed',
                  icon: Icons.store_mall_directory_outlined,
                  color: AppColors.error,
                  selected: status?.status == CanteenStatus.closed,
                  onTap: loading ? null : onSetClosed,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Paused/Closed blocks all new orders instantly. '
                  'Existing orders and the canteen queue remain unaffected.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.6)
                : color.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Tile ─────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
