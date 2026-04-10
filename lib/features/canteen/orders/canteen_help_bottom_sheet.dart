import 'package:flutter/material.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';

/// Help & Contact bottom sheet used in both the Canteen Orders screen
/// (AppBar quick-access) and the Canteen Profile screen.
class CanteenHelpBottomSheet extends StatelessWidget {
  const CanteenHelpBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Help & Contact',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _HelpTile(
            icon: Icons.phone_rounded,
            title: 'Call Canteen Admin',
            subtitle: '+91 98765 43210',
            color: AppColors.success,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _HelpTile(
            icon: Icons.restaurant_menu_rounded,
            title: 'How to mark an order ready',
            subtitle: 'Go to Verify tab → Scan student QR code',
            color: AppColors.info,
          ),
          const SizedBox(height: 10),
          _HelpTile(
            icon: Icons.print_rounded,
            title: 'How to print a slip',
            subtitle:
                'Open order card → Tap "Open Slip" → Tap "Mark Printed"',
            color: AppColors.warning,
          ),
          const SizedBox(height: 10),
          _HelpTile(
            icon: Icons.schedule_rounded,
            title: 'Scheduled orders',
            subtitle: 'Appear in the Queue tab grouped by pickup time',
            color: AppColors.statusScheduled,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
