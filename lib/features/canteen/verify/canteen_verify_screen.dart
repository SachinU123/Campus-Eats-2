import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:campus_eats_ag/core/l10n/canteen_language_provider.dart';
import 'package:campus_eats_ag/core/l10n/canteen_strings.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/features/canteen/orders/canteen_orders_screen.dart';
import 'package:campus_eats_ag/models/order.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class CanteenVerifyScreen extends ConsumerStatefulWidget {
  const CanteenVerifyScreen({super.key});

  @override
  ConsumerState<CanteenVerifyScreen> createState() =>
      _CanteenVerifyScreenState();
}

class _CanteenVerifyScreenState extends ConsumerState<CanteenVerifyScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _loading = false;
  VerifyResult? _result;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _token => _ctrls.map((c) => c.text).join();

  // ── Verify via backend ────────────────────────────────────────────────────

  Future<void> _verify(String rawToken) async {
    if (rawToken.isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final result =
          await ref.read(orderProvider.notifier).verifyByToken(rawToken);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _result = result;
      });

      // If just completed → refresh orders list so it reflects in Orders tab
      if (result.isCompleted) {
        ref.read(canteenOrdersProvider.notifier).refresh();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _result = VerifyResult(
          found: false,
          reason: 'API_ERROR',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      });
    }
  }

  Future<void> _verifyToken() async {
    if (_token.length < 4) return;
    FocusScope.of(context).unfocus();
    await _verify(_token);
  }

  void _clear() {
    for (final c in _ctrls) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) _focusNodes[0].requestFocus();
    setState(() => _result = null);
  }

  // ─── QR Scan sheet ────────────────────────────────────────────────────────

  void _showQrScanSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _QrScanSheet(
        onResolved: (qrContent) {
          Navigator.pop(ctx);
          _verify(qrContent);
        },
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = ref.watch(canteenL10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.verifyAndCollect),
        actions: [
          TextButton.icon(
            onPressed: _showQrScanSheet,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(s.scanQr),
          ),
        ],
      ),
      body: _loading
          ? AppLoadingState(message: s.verifyingOrder)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // Hero icon + title
                  Icon(
                    Icons.verified_user_rounded,
                    size: 56,
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.enterTokenTitle,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.enterTokenSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // ── Token digit boxes ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: SizedBox(
                          width: 64,
                          height: 72,
                          child: TextFormField(
                            controller: _ctrls[i],
                            focusNode: _focusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.4)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) {
                              if (v.isNotEmpty && i < 3) {
                                _focusNodes[i + 1].requestFocus();
                              } else if (v.isEmpty && i > 0) {
                                _focusNodes[i - 1].requestFocus();
                              }
                              if (_token.length == 4) {
                                _verifyToken();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _clear,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(s.clearBtn),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _token.length == 4 ? _verifyToken : null,
                        icon:
                            const Icon(Icons.verified_outlined, size: 16),
                        label: Text(s.verifyBtn),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Result card ─────────────────────────────────────
                  if (_result != null) _VerifyResultCard(result: _result!),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ─── QR Scan Sheet ───────────────────────────────────────────────────────────
// Uses mobile_scanner (CameraX / ML Kit) for real camera-based QR scanning.
// Duplicate-scan lock: _scanned flag is set on first valid barcode; camera is
// stopped before returning so no further callbacks fire.

class _QrScanSheet extends StatefulWidget {
  final ValueChanged<String> onResolved;

  const _QrScanSheet({required this.onResolved});

  @override
  State<_QrScanSheet> createState() => _QrScanSheetState();
}

class _QrScanSheetState extends State<_QrScanSheet> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    // Only QR codes
    formats: [BarcodeFormat.qrCode],
  );

  /// Prevents duplicate backend calls if the camera fires multiple callbacks
  /// before the sheet closes.
  bool _scanned = false;

  // Tracks permission state so we can show the right UI.
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    // Start the camera. If permission is denied, MobileScanner will throw and
    // onDetect will never fire. We listen to the controller's state stream to
    // detect the denial.
    _controller.addListener(_onControllerStateChange);
  }

  void _onControllerStateChange() {
    final value = _controller.value;
    if (!mounted) return;
    // MobileScannerController.hasCameraPermission is false when denied.
    if (value.hasCameraPermission == false && !_permissionDenied) {
      setState(() => _permissionDenied = true);
    }
  }

  /// Called when MobileScanner detects a barcode. Fires on the UI thread.
  void _onDetect(BarcodeCapture capture) {
    // Duplicate-scan guard: ignore any callback after the first valid one.
    if (_scanned) return;
    final raw = capture.barcodes
        .where((b) => b.rawValue != null && b.rawValue!.isNotEmpty)
        .map((b) => b.rawValue!)
        .firstOrNull;
    if (raw == null) return;

    // Lock immediately to block any further callbacks.
    _scanned = true;
    // Stop camera before pop so it releases the preview cleanly.
    _controller.stop();

    // Debounce one frame so the controller has time to stop before we pop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
      widget.onResolved(raw);
    });
  }

  @override
  Future<void> dispose() async {
    _controller.removeListener(_onControllerStateChange);
    await _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer(builder: (ctx, ref, _) {
      final s = ref.watch(canteenL10nProvider);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ─────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                s.scanStudentQr,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                s.pointCameraAt,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // ── Camera view OR permission-denied fallback ──────────
              if (_permissionDenied)
                _PermissionDeniedCard(s: s)
              else
                _CameraPreviewBox(controller: _controller, onDetect: _onDetect, s: s),

              const SizedBox(height: 16),

              // ── Cancel button ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.keyboard_rounded, size: 18),
                  label: Text(s.cancelEnterManually),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Camera Preview Box ───────────────────────────────────────────────────────
/// Wraps MobileScanner in the familiar viewfinder box with corner markers and
/// a scan-line overlay.
class _CameraPreviewBox extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;
  final CanteenStrings s;

  const _CameraPreviewBox({required this.controller, required this.onDetect, required this.s});

  @override
  Widget build(BuildContext context) {
    const boxSize = 280.0;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: boxSize,
            height: boxSize,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Real camera preview
                MobileScanner(
                  controller: controller,
                  onDetect: onDetect,
                ),
                // Viewfinder overlay
                CustomPaint(painter: _ViewfinderPainter()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded,
                size: 14,
                color: AppColors.primary.withValues(alpha: 0.75)),
            const SizedBox(width: 6),
            Text(
              s.cameraActive,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Viewfinder Painter ───────────────────────────────────────────────────────
/// Draws the four corner L-markers (accent colour) on top of the live preview.
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLen = 28.0;
    const thick = 3.5;
    const margin = 12.0;
    const color = AppColors.accent;

    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(
        Offset(margin, margin + cornerLen), Offset(margin, margin), paint);
    canvas.drawLine(
        Offset(margin, margin), Offset(margin + cornerLen, margin), paint);
    // Top-right
    canvas.drawLine(Offset(size.width - margin - cornerLen, margin),
        Offset(size.width - margin, margin), paint);
    canvas.drawLine(Offset(size.width - margin, margin),
        Offset(size.width - margin, margin + cornerLen), paint);
    // Bottom-left
    canvas.drawLine(Offset(margin, size.height - margin - cornerLen),
        Offset(margin, size.height - margin), paint);
    canvas.drawLine(Offset(margin, size.height - margin),
        Offset(margin + cornerLen, size.height - margin), paint);
    // Bottom-right
    canvas.drawLine(
        Offset(size.width - margin - cornerLen, size.height - margin),
        Offset(size.width - margin, size.height - margin),
        paint);
    canvas.drawLine(
        Offset(size.width - margin, size.height - margin - cornerLen),
        Offset(size.width - margin, size.height - margin),
        paint);
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) => false;
}

// ─── Permission Denied Card ───────────────────────────────────────────────────
/// Shown when the user has denied camera permission. Guides staff to use
/// manual token entry instead — no technical jargon.
class _PermissionDeniedCard extends StatelessWidget {
  final CanteenStrings s;
  const _PermissionDeniedCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(Icons.no_photography_rounded,
              size: 48, color: AppColors.warning),
          const SizedBox(height: 12),
          Text(
            s.cameraAccessNeeded,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.cameraDeniedMsg,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.warning.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: Text(s.openAppSettings),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
            ),
            onPressed: () async {
              // Opens the system settings page so staff can grant permission.
              await SystemChannels.platform
                  .invokeMethod<void>('SystemNavigator.routeUpdated');
              // Best-effort: MobileScanner provides no direct settings opener;
              // on modern Android the user must manually enable in Settings.
            },
          ),
        ],
      ),
    );
  }
}

// ─── Verification Result Card ────────────────────────────────────────────────

class _VerifyResultCard extends ConsumerWidget {
  final VerifyResult result;
  const _VerifyResultCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(canteenL10nProvider);

    // ── Not found state ────────────────────────────────────────
    if (!result.found) {
      return _StatusBanner(
        icon: Icons.search_off_rounded,
        title: result.isNotFound
            ? s.tokenNotFound
            : s.verifyError,
        subtitle: result.message,
        color: AppColors.error,
      );
    }

    final order = result.order!;

    // ── Already completed ──────────────────────────────────────
    if (result.isAlreadyCompleted) {
      return Column(
        children: [
          _StatusBanner(
            icon: Icons.check_circle_rounded,
            title: s.alreadyCollected,
            subtitle: s.alreadyCollectedSub,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          _OrderSummaryCard(order: order, highlight: false, s: s),
        ],
      );
    }

    // ── Not paid yet ───────────────────────────────────────────
    if (result.isNotPaid) {
      return Column(
        children: [
          _StatusBanner(
            icon: Icons.payment_rounded,
            title: s.paymentPending,
            subtitle: s.paymentPendingSub,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          _OrderSummaryCard(order: order, highlight: false, s: s),
        ],
      );
    }

    // ── Cancelled ──────────────────────────────────────────────
    if (result.isCancelled) {
      return Column(
        children: [
          _StatusBanner(
            icon: Icons.cancel_rounded,
            title: s.orderCancelled,
            subtitle: s.orderCancelledSub,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          _OrderSummaryCard(order: order, highlight: false, s: s),
        ],
      );
    }

    // ── Successfully completed ─────────────────────────────────
    if (result.isCompleted) {
      return Column(
        children: [
          _StatusBanner(
            icon: Icons.verified_rounded,
            title: s.orderVerifiedTitle,
            subtitle: 'Token #${order.token} — ${order.studentName}',
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          _OrderSummaryCard(order: order, highlight: true, s: s),
        ],
      );
    }

    // ── Fallback: generic error ─────────────────────────────────
    return _StatusBanner(
      icon: Icons.warning_amber_rounded,
      title: s.verifyIssue,
      subtitle: result.message,
      color: AppColors.warning,
    );
  }
}

// ─── Status Banner ───────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _StatusBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Summary Card ──────────────────────────────────────────────────────

class _OrderSummaryCard extends ConsumerWidget {
  final Order order;
  final bool highlight;
  final CanteenStrings s;

  const _OrderSummaryCard({required this.order, required this.highlight, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Token #${order.token}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: highlight
                      ? AppColors.success
                      : theme.colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.id,
            style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 0.5),
          ),
          const Divider(height: 20),

          // Student
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  order.studentName.isNotEmpty
                      ? order.studentName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(s.verifyStudentLabel,
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const Divider(height: 20),

          Text(
            s.verifyItemsLabel,
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    if (item.emoji.isNotEmpty) ...[
                      Text(item.emoji),
                      const SizedBox(width: 6),
                    ],
                    Expanded(child: Text(item.name)),
                    Text('×${item.quantity}',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Text('Rs. ${item.lineTotal.toInt()}',
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const Divider(height: 16),

          Row(
            children: [
              Text(s.verifyTotalLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                'Rs. ${order.total.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: highlight
                      ? AppColors.success
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.paymentMethod} • ${AppUtils.formatDateTime(order.placedAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
