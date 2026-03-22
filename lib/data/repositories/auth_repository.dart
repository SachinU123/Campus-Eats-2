import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_eats_ag/data/mock/mock_auth_data.dart';
import 'package:campus_eats_ag/models/user_profile.dart';

class AuthRepository {
  UserProfile? _currentUser;

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('current_user');
    if (json != null) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _currentUser = UserProfile.fromMap(map);
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  Future<UserProfile?> login(String email, String password) async {
    final user = MockAuthData.login(email, password);
    if (user != null) {
      _currentUser = user;
      await _persist(user);
    }
    return user;
  }

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String department,
    required String year,
    required String phone,
    required String role,
  }) async {
    final user = MockAuthData.register(
      name: name,
      email: email,
      department: department,
      year: year,
      phone: phone,
      role: role,
    );
    _currentUser = user;
    await _persist(user);
    return user;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
  }

  Future<void> _persist(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toMap()));
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
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

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String department,
    required String year,
    required String phone,
    required String role,
  }) async {
    final user = await ref.read(authRepositoryProvider).register(
          name: name,
          email: email,
          password: password,
          department: department,
          year: year,
          phone: phone,
          role: role,
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
