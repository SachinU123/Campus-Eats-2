import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/constants/app_design_tokens.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/data/repositories/theme_repository.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    if (user == null) {
      return const Scaffold(body: AppLoadingState(message: 'Loading profile…'));
    }

    final isFaculty = user.role == 'faculty';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero header ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isFaculty ? AppColors.warning : AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Profile',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFaculty
                        ? [
                            const Color(0xFFE67E22),
                            const Color(0xFFF39C12),
                          ]
                        : [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Avatar with gradient border ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Role pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          isFaculty
                              ? 'Faculty${user.department.isNotEmpty ? ' · ${user.department}' : ''}'
                              : '${user.department.isNotEmpty ? user.department : 'Student'}${user.year.isNotEmpty ? ' · ${user.year}' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxxl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Account Info ────────────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionLabel('Account Info'),
                      const SizedBox(height: AppSpacing.md),
                      _ProfileRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                      ),
                      const Divider(height: 20),
                      _ProfileRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: user.phone.isEmpty ? '—' : user.phone,
                      ),
                      if (isFaculty) ...[
                        const Divider(height: 20),
                        _ProfileRow(
                          icon: Icons.domain_rounded,
                          label: 'Department',
                          value: user.department.isEmpty
                              ? '—'
                              : user.department,
                        ),
                        const Divider(height: 20),
                        _ProfileRow(
                          icon: Icons.meeting_room_outlined,
                          label: 'Room / Office',
                          value: user.roomNumber.isEmpty
                              ? '—'
                              : user.roomNumber,
                          highlight: true,
                          highlightColor: AppColors.warning,
                        ),
                      ] else ...[
                        const Divider(height: 20),
                        _ProfileRow(
                          icon: Icons.school_outlined,
                          label: 'Department',
                          value: user.department.isEmpty
                              ? '—'
                              : user.department,
                        ),
                        const Divider(height: 20),
                        _ProfileRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Year',
                          value: user.year.isEmpty ? '—' : user.year,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Settings ───────────────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: AppSpacing.md, bottom: AppSpacing.sm),
                        child: AppSectionLabel('Settings'),
                      ),
                      _SettingsRow(
                        icon: isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        label: 'Dark Mode',
                        trailing: Switch(
                          value: themeMode == 2,
                          onChanged: (v) =>
                              ref.read(themeProvider.notifier).setMode(v ? 2 : 1),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Actions ─────────────────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      _ActionRow(
                        icon: Icons.receipt_long_rounded,
                        label: 'My Orders',
                        onTap: () => context.go('/student/orders'),
                      ),
                      const Divider(height: 1),
                      _ActionRow(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help coming soon')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _ActionRow(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        color: AppColors.error,
                        onTap: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon,
              size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: highlight
                      ? highlightColor
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 15)),
        ),
        trailing,
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
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: c.withValues(alpha: 0.45)),
          ],
        ),
      ),
    );
  }
}
