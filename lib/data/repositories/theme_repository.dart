import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_eats_ag/core/constants/app_constants.dart';

class ThemeNotifier extends Notifier<int> {
  // 0 = system, 1 = light, 2 = dark
  //
  // Default is 1 (light) rather than 0 (system) so that canteen auth
  // screens never randomly open in dark mode on devices where system
  // default is dark. Once the user explicitly selects dark it will be
  // persisted and respected on every subsequent launch.
  @override
  int build() => 1; // start light until load() completes

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // If no preference has ever been saved, default to 1 (light).
    final saved = prefs.getInt(AppConstants.prefThemeMode);
    state = saved ?? 1;
  }

  Future<void> setMode(int mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefThemeMode, mode);
  }

  void toggleDark() {
    setMode(state == 2 ? 1 : 2);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, int>(() {
  return ThemeNotifier();
});
