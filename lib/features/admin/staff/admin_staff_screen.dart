import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/settings_repository.dart';

class AdminStaffScreen extends ConsumerStatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  ConsumerState<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends ConsumerState<AdminStaffScreen> {
  List<Map<String, dynamic>> _staff = [];
  bool _loading = true;
  String? _error;
  final Set<String> _toggling = {};

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final staff = await repo.getStaff();
      if (mounted) setState(() { _staff = staff; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> staff) async {
    final id = staff['id'] as String;
    final current = staff['isActive'] as bool? ?? true;
    setState(() => _toggling.add(id));
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final updated = await repo.setStaffActive(id, isActive: !current);
      if (mounted) {
        final idx = _staff.indexWhere((s) => s['id'] == id);
        if (idx >= 0) setState(() => _staff[idx] = updated);
        _showSnack(
          !current ? '${staff['name']} account enabled' : '${staff['name']} account disabled',
          !current ? AppColors.success : Colors.grey,
        );
      }
    } catch (e) {
      _showSnack('Failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _toggling.remove(id));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Accounts',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStaff,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 52, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        onPressed: _loadStaff,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStaff,
                  child: _staff.isEmpty
                      ? const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 400,
                            child: EmptyState(
                              icon: Icons.people_outline_rounded,
                              title: 'No staff accounts',
                              subtitle: 'Canteen staff accounts appear here',
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _staff.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final s = _staff[i];
                            final id = s['id'] as String;
                            final name = s['name'] as String? ?? '—';
                            final phone = s['phoneNumber'] as String? ?? '—';
                            final role = s['role'] as String? ?? 'canteen';
                            final isActive = s['isActive'] as bool? ?? true;
                            final isAdmin = role == 'canteen_admin';
                            final isToggling = _toggling.contains(id);

                            return AppCard(
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isActive
                                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                        : Colors.grey.withValues(alpha: 0.15),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: isActive
                                            ? theme.colorScheme.primary
                                            : Colors.grey,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: isActive ? null : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (isAdmin)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary
                                                      .withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'ADMIN',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Text(
                                          phone,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Active toggle — cannot deactivate own admin account
                                  isToggling
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Tooltip(
                                          message: isActive ? 'Disable account' : 'Enable account',
                                          child: Switch(
                                            value: isActive,
                                            activeThumbColor: AppColors.success,
                                            onChanged: isAdmin
                                                ? null // Cannot disable admin accounts
                                                : (_) => _toggleActive(s),
                                          ),
                                        ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
