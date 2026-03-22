import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_ag/core/constants/app_constants.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/data/repositories/theme_repository.dart';

class CanteenProfileScreen extends ConsumerWidget {
  const CanteenProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Staff avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user.name,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Canteen Staff',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Staff Info card ──────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, Icons.badge_outlined, 'Staff Info'),
                  const SizedBox(height: 14),
                  _ProfileRow(
                    Icons.person_outline_rounded,
                    'Full Name',
                    user.name,
                  ),
                  const Divider(height: 18),
                  _ProfileRow(
                    Icons.phone_outlined,
                    'Phone',
                    user.phone.isEmpty ? '—' : '+91 ${user.phone}',
                  ),
                  const Divider(height: 18),
                  _ProfileRow(
                    Icons.storefront_outlined,
                    'Canteen',
                    AppConstants.canteenName,
                  ),
                  const Divider(height: 18),
                  _ProfileRow(
                    Icons.work_outline_rounded,
                    'Role',
                    'Canteen Staff',
                  ),
                  const Divider(height: 18),
                  _ProfileRow(
                    Icons.schedule_outlined,
                    'Shift Timing',
                    '8:00 AM – 4:00 PM',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Theme / Display card ────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, Icons.tune_outlined, 'Preferences'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.dark_mode_outlined, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Dark Mode')),
                      Switch(
                        value: themeMode == 2,
                        onChanged: (v) =>
                            ref.read(themeProvider.notifier).setMode(v ? 2 : 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Device Info card ────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                      context, Icons.devices_rounded, 'Device & Hardware'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 13, color: AppColors.info),
                        const SizedBox(width: 6),
                        Text(
                          'Hardware integration coming soon',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DeviceRow(Icons.perm_device_information_outlined,
                      'Device Name', 'Counter Terminal #1'),
                  const Divider(height: 18),
                  _DeviceRow(Icons.point_of_sale_outlined, 'Counter Device',
                      'Counter A'),
                  const Divider(height: 18),
                  _DeviceRow(
                      Icons.fingerprint_rounded, 'Device ID', 'CTERM-001-VPP'),
                  const Divider(height: 18),
                  _DeviceStatusRow(Icons.print_outlined, 'Printer Status',
                      'Not Connected', false),
                  const Divider(height: 18),
                  _DeviceStatusRow(Icons.qr_code_scanner_rounded,
                      'Scanner Status', 'Ready', true),
                  const Divider(height: 18),
                  _DeviceRow(Icons.sync_outlined, 'Last Sync', '—'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Actions card ────────────────────────────────────────
            AppCard(
              child: Column(
                children: [
                  _ActionRow(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 8),
                  _ActionRow(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    color: AppColors.error,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content:
            const Text('Are you sure you want to logout from canteen staff?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DeviceRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _DeviceStatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final bool isConnected;

  const _DeviceStatusRow(this.icon, this.label, this.status, this.isConnected);

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? AppColors.success : AppColors.textSecondaryLight;
    return Row(
      children: [
        Icon(icon,
            size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: TextStyle(color: c, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: c.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
