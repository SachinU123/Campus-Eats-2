import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_eats_ag/core/constants/app_constants.dart';

class ThemeNotifier extends Notifier<int> {
  // 0 = system, 1 = light, 2 = dark
  @override
  int build() => 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(AppConstants.prefThemeMode) ?? 0;
  }

  Future<void> setMode(int mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefThemeMode, mode);
  }

  void toggleDark() {
    if (state == 2) {
      setMode(1);
    } else {
      setMode(2);
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, int>(() {
  return ThemeNotifier();
});
