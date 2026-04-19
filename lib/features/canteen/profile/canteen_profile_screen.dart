import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_ag/core/constants/app_constants.dart';
import 'package:campus_eats_ag/core/l10n/canteen_language_provider.dart';
import 'package:campus_eats_ag/core/l10n/canteen_strings.dart';
import 'package:campus_eats_ag/core/services/thermal_printer_service.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/data/repositories/theme_repository.dart';
import 'package:campus_eats_ag/features/canteen/orders/canteen_help_bottom_sheet.dart';

class CanteenProfileScreen extends ConsumerWidget {
  const CanteenProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final s = ref.watch(canteenL10nProvider);
    final currentLang = ref.watch(canteenLangProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.staffProfile)),
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
                    s.canteenStaff,
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
                  _sectionTitle(context, Icons.badge_outlined, s.sectionStaffInfo),
                  const SizedBox(height: 14),
                  _ProfileRow(
                    Icons.person_outline_rounded,
                    s.labelFullName,
                    user.name,
                  ),
                  const Divider(height: 18),
                  _ProfileRow(
                    Icons.phone_outlined,
                    s.labelPhone,
                    user.phone.isEmpty ? '—' : '+91 ${user.phone}',
                  ),
                  const Divider(height: 18),
                  _ProfileRow(
                    Icons.storefront_outlined,
                    s.labelCanteen,
                    AppConstants.canteenName,
                  ),
                  const Divider(height: 18),
                  _ProfileRow(
                    Icons.work_outline_rounded,
                    s.labelRole,
                    s.canteenStaff,
                  ),
                  const Divider(height: 18),
                  _ProfileRow(
                    Icons.schedule_outlined,
                    s.labelShiftTiming,
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
                  _sectionTitle(context, Icons.tune_outlined, s.sectionAppearance),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        themeMode == 2
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 20,
                        color: themeMode == 2 ? const Color(0xFF9575CD) : AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.darkMode),
                            Text(
                              themeMode == 2 ? s.darkModeActive : s.lightModeActive,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
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

            // ── Language selector card ───────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, Icons.translate_rounded, s.sectionLanguage),
                  const SizedBox(height: 4),
                  Text(
                    s.languageSub,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: currentLang,
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(canteenLangProvider.notifier).setLanguage(v);
                      }
                    },
                    child: Column(
                      children: ['en', 'hi', 'mr'].map((code) {
                        final label =
                            CanteenStrings.fromCode(code).languageName;
                        final isSelected = currentLang == code;
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => ref
                              .read(canteenLangProvider.notifier)
                              .setLanguage(code),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Radio<String>(value: code),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Thermal Printer card (Phase 11) ─────────────────────────
            _ThermalPrinterCard(s: s),
            const SizedBox(height: 16),

            // ── Device Info card ────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                      context, Icons.devices_rounded, s.sectionDevice),
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
                          s.deviceHwSoon,
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
                      s.labelDeviceName, 'Counter Terminal #1'),
                  const Divider(height: 18),
                  _DeviceRow(Icons.point_of_sale_outlined, s.labelCounterDevice,
                      'Counter A'),
                  const Divider(height: 18),
                  _DeviceRow(
                      Icons.fingerprint_rounded, s.labelDeviceId, 'CTERM-001-VPP'),
                  const Divider(height: 18),
                  _DeviceStatusRow(Icons.print_outlined, s.labelPrinterStatus,
                      s.printerNotConnected, false),
                  const Divider(height: 18),
                  _DeviceStatusRow(Icons.qr_code_scanner_rounded,
                      s.labelScannerStatus, s.scannerReady, true),
                  const Divider(height: 18),
                  _DeviceRow(Icons.sync_outlined, s.labelLastSync, '—'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Actions card ────────────────────────────────────────
            AppCard(
              child: Column(
                children: [
                  _ActionRow(
                    icon: Icons.delete_sweep_outlined,
                    label: s.clearHistory,
                    color: AppColors.warning,
                    onTap: () => _confirmClearHistory(context, ref, s),
                  ),
                  const Divider(height: 8),
                  _ActionRow(
                    icon: Icons.help_outline_rounded,
                    label: s.helpContact,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => const CanteenHelpBottomSheet(),
                    ),
                  ),
                  const Divider(height: 8),
                  _ActionRow(
                    icon: Icons.logout_rounded,
                    label: s.logout,
                    color: AppColors.error,
                    onTap: () => _confirmLogout(context, ref, s),
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

  Future<void> _confirmClearHistory(
      BuildContext context, WidgetRef ref, CanteenStrings s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.clearHistoryTitle),
        content: Text(s.clearHistoryBody),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: Text(s.clearFromView),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(orderRepositoryProvider);
        final count = await repo.clearCompletedHistory();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.clearedCount(count))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${s.failedMsg}: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref, CanteenStrings s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.logoutTitle),
        content: Text(s.logoutBody),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(s.logoutConfirm),
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

// ─── Thermal Printer Card (Phase 11) ─────────────────────────────────────────
//
// Shows paired printer status and allows canteen staff to scan for and pair
// a Bluetooth ESC/POS thermal printer (e.g. 80mm roll receipt printer).
// Once paired, the printer address is persisted in SharedPreferences.
// Fallback PDF print remains available regardless of pairing state.

class _ThermalPrinterCard extends StatefulWidget {
  final CanteenStrings s;
  const _ThermalPrinterCard({required this.s});

  @override
  State<_ThermalPrinterCard> createState() => _ThermalPrinterCardState();
}

class _ThermalPrinterCardState extends State<_ThermalPrinterCard> {
  final _svc = ThermalPrinterService.instance;
  bool _scanning = false;
  List<DiscoveredPrinter> _discovered = [];

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _discovered = [];
    });
    final found = await _svc.scanBluetooth();
    if (mounted) setState(() { _scanning = false; _discovered = found; });
    if (!mounted) return;
    if (found.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.s.thermalNotFound} (No BT printers found)'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    _showPairSheet();
  }

  void _showPairSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.s.pairPrinter,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ..._discovered.map((p) => ListTile(
              leading: const Icon(Icons.print_rounded),
              title: Text(p.name),
              subtitle: Text(p.address),
              trailing: const Icon(Icons.bluetooth_rounded, color: AppColors.primary),
              onTap: () async {
                Navigator.pop(context);
                await _svc.savePaired(PairedPrinterInfo(
                  address: p.address,
                  name: p.name,
                  type: p.savedType,
                ));
                if (mounted) setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.s.thermalConnected}: ${p.name}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _clear() async {
    await _svc.clearPaired();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final paired = _svc.pairedPrinter;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.print_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              widget.s.thermalPrinterTitle,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ]),
          const SizedBox(height: 10),

          // Status
          if (paired != null) ...[
            Row(children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Expanded(child: Text('${widget.s.printerPairedAs} ${paired.name} (${paired.address})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bluetooth_disabled_rounded, size: 16),
                label: Text(widget.s.clearPrinter),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: _clear,
              ),
            ),
          ] else ...[
            Text(widget.s.thermalDisconnected,
                style: const TextStyle(fontSize: 13, color: AppColors.warning)),
            const SizedBox(height: 10),
          ],

          // Scan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _scanning
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.bluetooth_searching_rounded, size: 16),
              label: Text(_scanning ? widget.s.thermalPrinting : widget.s.pairPrinter),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _scanning ? null : _scan,
            ),
          ),

          const SizedBox(height: 6),
          Text(
            widget.s.thermalUseFallback,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
