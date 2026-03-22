import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';
import 'package:campus_eats_ag/core/utils/app_utils.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/models/order.dart';

class CanteenVerifyScreen extends ConsumerStatefulWidget {
  const CanteenVerifyScreen({super.key});

  @override
  ConsumerState<CanteenVerifyScreen> createState() => _CanteenVerifyScreenState();
}

class _CanteenVerifyScreenState extends ConsumerState<CanteenVerifyScreen> {
  final List<TextEditingController> _ctrls = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  Order? _result;
  String? _error;

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

  void _lookup() {
    final token = _token;
    if (token.length < 4) return;

    final order = ref.read(orderProvider.notifier).findByToken(token);
    setState(() {
      if (order != null) {
        _result = order;
        _error = null;
      } else {
        _result = null;
        _error = 'No order found for token $token';
      }
    });
  }

  void _clear() {
    for (final c in _ctrls) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {
      _result = null;
      _error = null;
    });
  }

  void _refreshResult() {
    if (_result != null) {
      final updated = ref.read(orderProvider.notifier).findById(_result!.id);
      setState(() => _result = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(orderProvider, (_, _) => _refreshResult());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Order'),
        actions: [
          TextButton.icon(
            onPressed: () => _showQrScanSheet(context),
            icon: const Icon(Icons.qr_code_rounded),
            label: const Text('Scan QR'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Text(
              'Enter Token Number',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the 4-digit token to look up an order',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Token input boxes
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 3) {
                          _focusNodes[i + 1].requestFocus();
                        }
                        if (_token.length == 4) {
                          FocusScope.of(context).unfocus();
                          _lookup();
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
                  label: const Text('Clear'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _token.length == 4 ? _lookup : null,
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('Lookup'),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                  ],
                ),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 24),
              _VerificationResultCard(
                order: _result!,
                onStatusChanged: _refreshResult,
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showQrScanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _QrScanSheet(
        onResolved: (order) {
          Navigator.pop(ctx);
          setState(() {
            _result = order;
            _error = null;
          });
        },
        onError: (msg) {
          Navigator.pop(ctx);
          setState(() {
            _result = null;
            _error = msg;
          });
        },
      ),
    );
  }
}

class _QrScanSheet extends ConsumerStatefulWidget {
  final ValueChanged<Order> onResolved;
  final ValueChanged<String> onError;

  const _QrScanSheet({required this.onResolved, required this.onError});

  @override
  ConsumerState<_QrScanSheet> createState() => _QrScanSheetState();
}

class _QrScanSheetState extends ConsumerState<_QrScanSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Scan QR Code',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Mock camera view
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner markers
                  ..._buildCornerMarkers(),
                  // Scan line
                  AnimatedBuilder(
                    animation: _scanAnim,
                    builder: (ctx, _) {
                      return Positioned(
                        top: 20 + _scanAnim.value * 220,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 2,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.accent,
                                AppColors.accent,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Center icon
                  Center(
                    child: Icon(
                      Icons.qr_code_rounded,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Point at the QR code',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Simulate Scan',
              icon: Icons.qr_code_scanner_rounded,
              onTap: () => _simulateScan(context),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateScan(BuildContext context) {
    final orders = ref.read(orderProvider.notifier).getActive();
    if (orders.isEmpty) {
      widget.onError('No active orders to simulate');
      return;
    }
    final order = orders.first;
    widget.onResolved(order);
  }

  List<Widget> _buildCornerMarkers() {
    const size = 24.0;
    const thick = 3.0;
    const color = AppColors.accent;

    Widget corner(double? top, double? bottom, double? left, double? right) {
      return Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _CornerPainter(top != null, left != null, color, thick)),
        ),
      );
    }

    return [
      corner(10, null, 10, null),
      corner(10, null, null, 10),
      corner(null, 10, 10, null),
      corner(null, 10, null, 10),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final Color color;
  final double thickness;

  const _CornerPainter(this.isTop, this.isLeft, this.color, this.thickness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

class _VerificationResultCard extends ConsumerWidget {
  final Order order;
  final VoidCallback onStatusChanged;
  const _VerificationResultCard({required this.order, required this.onStatusChanged});

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
                  color: theme.colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(order.id, style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 0.5)),
          const Divider(height: 20),

          // Student info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  order.studentName[0].toUpperCase(),
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.studentName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(order.studentDept, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const Divider(height: 20),

          Text('Ordered Items', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(item.emoji),
                    const SizedBox(width: 6),
                    Expanded(child: Text(item.name)),
                    Text('x${item.quantity}', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Text('Rs. ${item.lineTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const Divider(height: 16),

          Row(
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                'Rs. ${order.total.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.paymentMethod} • ${AppUtils.formatDateTime(order.placedAt)}',
            style: theme.textTheme.bodySmall,
          ),

          if (order.status == 'Collected') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This order has already been collected',
                      style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            _ActionButtons(order: order, onStatusChanged: onStatusChanged),
          ],
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  final Order order;
  final VoidCallback onStatusChanged;
  const _ActionButtons({required this.order, required this.onStatusChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(orderProvider.notifier);

    if (order.status == 'Preparing' || order.status == 'Scheduled') {
      return AppButton(
        label: 'Mark as Ready',
        icon: Icons.notifications_active_rounded,
        onTap: () async {
          await notifier.updateStatus(order.id, 'Ready');
          onStatusChanged();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order marked as Ready')),
            );
          }
        },
      );
    }

    if (order.status == 'Ready') {
      return AppButton(
        label: 'Mark as Verified',
        icon: Icons.verified_rounded,
        onTap: () async {
          await notifier.updateStatus(order.id, 'Verified');
          onStatusChanged();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order Verified')),
            );
          }
        },
      );
    }

    if (order.status == 'Verified') {
      return AppButton(
        label: 'Mark as Collected',
        icon: Icons.check_circle_rounded,
        onTap: () async {
          await notifier.updateStatus(order.id, 'Collected');
          onStatusChanged();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order Collected - Thank you!')),
            );
          }
        },
      );
    }

    return const SizedBox.shrink();
  }
}
