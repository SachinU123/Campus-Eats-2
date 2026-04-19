import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:campus_eats_ag/core/constants/api_config.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/data/repositories/cart_repository.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/data/repositories/payment_repository.dart';
import 'package:campus_eats_ag/data/repositories/settings_repository.dart';
import 'package:campus_eats_ag/models/order.dart';
import 'package:campus_eats_ag/models/order_item.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> extra;

  const PaymentScreen({super.key, required this.extra});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Razorpay? _razorpay;

  static const String _method = 'UPI';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  // ─── Razorpay Callbacks ───────────────────────────────────────

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    dev.log(
      '[PAYMENT] Razorpay success: paymentId=${response.paymentId} '
      'orderId=${response.orderId} signature=${response.signature != null ? "[sig]" : "null"}',
      name: 'PaymentScreen',
    );
    _verifyAndFinalize(
      razorpayOrderId: response.orderId!,
      razorpayPaymentId: response.paymentId!,
      razorpaySignature: response.signature!,
    );
  }

  void _onPaymentError(PaymentFailureResponse response) {
    dev.log(
      '[PAYMENT] Razorpay error: code=${response.code} msg=${response.message}',
      name: 'PaymentScreen',
      level: 900,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Payment failed: ${response.message ?? "Unknown error"}';
      });
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    dev.log('[PAYMENT] External wallet: ${response.walletName}', name: 'PaymentScreen');
  }

  // ─── Main Payment Flow ────────────────────────────────────────
  // Flow: placeOrder → createPaymentOrder → open Razorpay → verify → navigate

  Future<void> _processPayment(
    BuildContext context,
    double total,
    DateTime? scheduledFor,
  ) async {
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // Step 1: Create the order on backend
      final user = ref.read(authProvider);
      final cartItems = ref.read(cartProvider);
      final orderItems = cartItems.map(OrderItem.fromCartItem).toList();

      dev.log('[PAYMENT] Step 1: Creating order...', name: 'PaymentScreen');

      final order = await ref.read(orderProvider.notifier).placeOrder(
            studentId: user?.id ?? '',
            studentName: user?.name ?? 'Student',
            studentDept: user?.department ?? '',
            items: orderItems,
            total: total,
            paymentMethod: _method,
            scheduledFor: scheduledFor,
          );

      dev.log('[PAYMENT] Step 1 OK: orderId=${order.id}', name: 'PaymentScreen');

      // Step 2: Create Razorpay payment order on backend
      dev.log('[PAYMENT] Step 2: Creating payment order...', name: 'PaymentScreen');
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final paymentData = await paymentRepo.createPaymentOrder(order.id);

      dev.log(
        '[PAYMENT] Step 2 OK: razorpayOrderId=${paymentData['razorpayOrderId']} '
        'amount=${paymentData['amount']}',
        name: 'PaymentScreen',
      );

      // Step 3: Open Razorpay checkout
      _openRazorpay(order: order, paymentData: paymentData);

      // Note: setState is done in callbacks (_onPaymentSuccess / _onPaymentError)
    } catch (e) {
      dev.log('[PAYMENT] Error in payment flow: $e', name: 'PaymentScreen', level: 1000);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _openRazorpay({required Order order, required Map<String, dynamic> paymentData}) {
    final options = {
      'key': paymentData['keyId'] ?? ApiConfig.razorpayKeyId,
      'amount': paymentData['amount'], // in paise
      'currency': paymentData['currency'] ?? 'INR',
      'order_id': paymentData['razorpayOrderId'],
      'name': 'Campus Eats',
      'description': 'Order #${order.token}',
      'prefill': {
        'contact': ref.read(authProvider)?.phone ?? '',
        'email': ref.read(authProvider)?.email ?? '',
      },
      'theme': {'color': '#FF6B35'},
    };

    dev.log('[PAYMENT] Opening Razorpay with options: ${options.toString().replaceAll(RegExp(r'key: [^,}]+'), 'key: [hidden]')}', name: 'PaymentScreen');

    try {
      _razorpay!.open(options);
    } on PlatformException catch (e) {
      dev.log('[PAYMENT] PlatformException opening Razorpay: $e', name: 'PaymentScreen', level: 1000);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not open payment: ${e.message}';
      });
    }
  }

  // Step 4: Verify payment with backend (called after Razorpay callback)
  Future<void> _verifyAndFinalize({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // Find the pending order from the current order list
      final orders = ref.read(orderProvider);
      final Order? pendingOrder = orders.isNotEmpty ? orders.first : null;

      if (pendingOrder == null) {
        throw Exception('Could not find order to verify payment');
      }

      dev.log('[PAYMENT] Step 4: Verifying payment for orderId=${pendingOrder.id}', name: 'PaymentScreen');

      final paymentRepo = ref.read(paymentRepositoryProvider);
      await paymentRepo.verifyPayment(
        orderId: pendingOrder.id,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );

      dev.log('[PAYMENT] Step 4 OK: payment verified, order is now PAID', name: 'PaymentScreen');

      await ref.read(cartProvider.notifier).clear();
      setState(() => _isLoading = false);

      if (mounted) {
        context.go('/student/success', extra: pendingOrder);
      }
    } catch (e) {
      dev.log('[PAYMENT] Verify error: $e', name: 'PaymentScreen', level: 1000);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Payment verification failed: ${e.toString().replaceFirst("Exception: ", "")}';
        });
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = (widget.extra['subtotal'] as num?)?.toDouble() ?? 0;
    final scheduledForStr = widget.extra['scheduledFor'] as String?;
    final scheduledFor =
        scheduledForStr != null ? DateTime.parse(scheduledForStr) : null;

    // Phase 7: Check canteen operational status for UX pre-check
    final statusAsync = ref.watch(canteenStatusProvider);
    final canteenStatus = statusAsync.asData?.value;
    final isCanteenOpen = canteenStatus?.isOpen ?? true;



    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_rounded,
                                color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Order Summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Subtotal'),
                            const Spacer(),
                            Text(
                              'Rs. ${subtotal.toInt()}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Text('Convenience Fee'),
                            Spacer(),
                            Text('Free',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            const Spacer(),
                            Text(
                              'Rs. ${subtotal.toInt()}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (scheduledFor != null) ...[
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 16, color: Color(0xFF00838F)),
                              const SizedBox(width: 6),
                              Text(
                                'Scheduled for ${TimeOfDay.fromDateTime(scheduledFor).format(context)}',
                                style: const TextStyle(
                                  color: Color(0xFF00838F),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Payment Method',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),

                  // UPI only — single, pre-selected card
                  AppCard(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UPI',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                'Google Pay, PhonePe, Paytm',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.radio_button_checked,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),

                  // Phase 7: Canteen closed/paused UX banner
                  if (!isCanteenOpen)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: canteenStatus?.status == CanteenStatus.paused
                            ? Colors.orange.withValues(alpha: 0.10)
                            : Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: canteenStatus?.status == CanteenStatus.paused
                              ? Colors.orange.withValues(alpha: 0.3)
                              : Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            canteenStatus?.status == CanteenStatus.paused
                                ? Icons.pause_circle_rounded
                                : Icons.store_mall_directory_outlined,
                            size: 20,
                            color: canteenStatus?.status == CanteenStatus.paused
                                ? Colors.orange
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              canteenStatus?.customerNotice ??
                                  'Canteen is not accepting orders right now.',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color:
                                    canteenStatus?.status == CanteenStatus.paused
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_errorMessage != null)

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Security note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security_rounded,
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Payments are secured via Razorpay',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              child: AppButton(
                label: isCanteenOpen
                    ? 'Pay Rs. ${subtotal.toInt()} via UPI'
                    : 'Ordering Unavailable',
                isLoading: _isLoading,
                onTap: isCanteenOpen
                    ? () => _processPayment(context, subtotal, scheduledFor)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
