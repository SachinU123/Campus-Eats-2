import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/data/api/api_client.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';

/// Payment repository handling Razorpay backend integration.
class PaymentRepository {
  final ApiClient _api;

  PaymentRepository(this._api);

  /// Create a Razorpay order on the backend for the given CampusEats order.
  /// Returns { razorpayOrderId, amount (in paise), currency, keyId }.
  Future<Map<String, dynamic>> createPaymentOrder(String orderId) async {
    final result = await _api.post('/payments/create-order', body: {
      'orderId': orderId,
    });

    if (!result.isSuccess) {
      throw Exception(result.message);
    }

    return result.data as Map<String, dynamic>;
  }

  /// Verify Razorpay payment on the backend.
  /// Backend validates signature and finalizes order if successful.
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final result = await _api.post('/payments/verify', body: {
      'orderId': orderId,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    });

    if (!result.isSuccess) {
      throw Exception(result.message);
    }

    return result.data as Map<String, dynamic>;
  }

  /// Get payment info for an order.
  Future<Map<String, dynamic>?> getPayment(String orderId) async {
    final result = await _api.get('/payments/$orderId');
    if (!result.isSuccess) return null;
    return result.data as Map<String, dynamic>;
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(apiClientProvider));
});
