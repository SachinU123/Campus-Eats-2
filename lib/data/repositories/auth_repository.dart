import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_eats_ag/data/api/api_client.dart';
import 'package:campus_eats_ag/models/user_profile.dart';

/// Global API client instance shared across all repositories.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class AuthRepository {
  final ApiClient _api;
  UserProfile? _currentUser;

  AuthRepository(this._api);

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Initialize: restore session from local storage and validate token.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');
    final userJson = prefs.getString('current_user');

    if (accessToken != null && refreshToken != null && userJson != null) {
      _api.setTokens(access: accessToken, refresh: refreshToken);
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserProfile.fromMap(map);
      } catch (_) {
        _currentUser = null;
      }

      // Validate token by calling /auth/me
      final result = await _api.get('/auth/me');
      if (!result.isSuccess) {
        // Try refreshing
        final refreshed = await _refreshTokens();
        if (!refreshed) {
          await _clearSession();
        }
      }
    }
  }

  /// Student registration.
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    final result = await _api.post('/auth/student/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
    });

    if (!result.isSuccess) {
      throw Exception(result.message);
    }

    final data = result.data as Map<String, dynamic>;
    final user = _parseUser(data['user'] as Map<String, dynamic>);
    await _saveSession(
      user: user,
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    return user;
  }

  /// Student login (email + password).
  Future<UserProfile?> login(String email, String password) async {
    final result = await _api.post('/auth/student/login', body: {
      'email': email,
      'password': password,
    });

    if (!result.isSuccess) return null;

    final data = result.data as Map<String, dynamic>;
    final user = _parseUser(data['user'] as Map<String, dynamic>);
    await _saveSession(
      user: user,
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    return user;
  }

  /// Request OTP for canteen login.
  Future<Map<String, dynamic>> requestCanteenOtp(String phoneNumber) async {
    final result = await _api.post('/auth/canteen/request-otp', body: {
      'phoneNumber': phoneNumber,
    });

    if (!result.isSuccess) {
      throw Exception(result.message);
    }

    return result.data as Map<String, dynamic>;
  }

  /// Verify canteen OTP and login.
  Future<UserProfile?> verifyCanteenOtp({
    required String phoneNumber,
    required String otp,
    String? deviceId,
    String? deviceName,
  }) async {
    final result = await _api.post('/auth/canteen/verify-otp', body: {
      'phoneNumber': phoneNumber,
      'otp': otp,
      // ignore: use_null_aware_elements
      if (deviceId != null) 'deviceId': deviceId,
      // ignore: use_null_aware_elements
      if (deviceName != null) 'deviceName': deviceName,
    });

    if (!result.isSuccess) {
      throw Exception(result.message ?? 'Invalid OTP');
    }

    final data = result.data as Map<String, dynamic>;
    final user = _parseUser(data['user'] as Map<String, dynamic>);
    await _saveSession(
      user: user,
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    return user;
  }

  /// Phone-based canteen login (after OTP verified).
  /// Simplified alias used by auth notifier.
  Future<UserProfile?> loginByPhone(String phone) async {
    // This is only used as fallback — real flow uses verifyCanteenOtp
    return _currentUser;
  }

  Future<void> logout() async {
    if (_api.refreshToken != null) {
      await _api.post('/auth/logout', body: {
        'refreshToken': _api.refreshToken,
      });
    }
    await _clearSession();
  }

  // ─── Token Management ──────────────────────────────────────

  Future<bool> _refreshTokens() async {
    final currentRefresh = _api.refreshToken;
    if (currentRefresh == null) return false;

    final result = await _api.post('/auth/refresh', body: {
      'refreshToken': currentRefresh,
    });

    if (!result.isSuccess) return false;

    final data = result.data as Map<String, dynamic>;
    _api.setTokens(
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['accessToken'] as String);
    await prefs.setString('refresh_token', data['refreshToken'] as String);

    return true;
  }

  // ─── Helpers ───────────────────────────────────────────────

  UserProfile _parseUser(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String? ?? '',
      department: '',
      year: '',
      role: data['role'] as String,
      phone: data['phoneNumber'] as String? ?? '',
    );
  }

  Future<void> _saveSession({
    required UserProfile user,
    required String accessToken,
    required String refreshToken,
  }) async {
    _currentUser = user;
    _api.setTokens(access: accessToken, refresh: refreshToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toMap()));
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> _clearSession() async {
    _currentUser = null;
    _api.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}

// ─── Providers ─────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider));
});

class AuthNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    return ref.read(authRepositoryProvider).currentUser;
  }

  Future<bool> login(String email, String password) async {
    final user = await ref.read(authRepositoryProvider).login(email, password);
    state = user;
    return user != null;
  }

  /// Phone-based canteen login (after OTP verified in UI).
  Future<bool> loginByPhone(String phone) async {
    // After OTP verification, user is already set via verifyCanteenOtp
    final repo = ref.read(authRepositoryProvider);
    state = repo.currentUser;
    return repo.currentUser != null;
  }

  /// Request OTP for canteen login.
  Future<Map<String, dynamic>> requestCanteenOtp(String phone) async {
    return ref.read(authRepositoryProvider).requestCanteenOtp(phone);
  }

  /// Verify OTP and login canteen user.
  Future<bool> verifyCanteenOtp({
    required String phone,
    required String otp,
  }) async {
    final user = await ref.read(authRepositoryProvider).verifyCanteenOtp(
          phoneNumber: phone,
          otp: otp,
        );
    state = user;
    return user != null;
  }

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    // Legacy params kept for backward compat but ignored
    String department = '',
    String year = '',
    String role = 'student',
  }) async {
    final user = await ref.read(authRepositoryProvider).register(
          name: name,
          email: email,
          password: password,
          phoneNumber: phone,
        );
    state = user;
    return user;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserProfile?>(() {
  return AuthNotifier();
});
