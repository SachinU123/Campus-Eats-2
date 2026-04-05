/// CampusEats API configuration.
/// Change [baseUrl] to match your backend server address.
class ApiConfig {
  ApiConfig._();

  // For Android emulator use 10.0.2.2, for physical device use your machine's IP
  static const String baseUrl = 'https://campus-eats-backend-2uhx.onrender.com/api/v1';

  // Razorpay TEST key (public key only — safe for frontend)
  static const String razorpayKeyId = 'rzp_test_xxxxxxxxxx';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
