/// ─── Canteen Language Provider — Phase 9 ────────────────────────────────────
///
/// Persists canteen staff's language choice to SharedPreferences.
/// Key: 'canteen_language'  Values: 'en' | 'hi' | 'mr'
/// Default: 'en' (English).
///
/// Usage:
///   final s = ref.watch(canteenL10nProvider);
///   Text(s.orders);
///
/// Changing language:
///   ref.read(canteenLangProvider.notifier).setLanguage('hi');

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_eats_ag/core/l10n/canteen_strings.dart';

const _prefKey = 'canteen_language';

/// Notifier — holds the language code string ('en' | 'hi' | 'mr').
class CanteenLangNotifier extends Notifier<String> {
  @override
  String build() => 'en'; // default until load() runs at startup

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && ['en', 'hi', 'mr'].contains(saved)) {
      state = saved;
    }
  }

  Future<void> setLanguage(String code) async {
    if (!['en', 'hi', 'mr'].contains(code)) return;
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }
}

/// Provider for the raw language code string.
final canteenLangProvider = NotifierProvider<CanteenLangNotifier, String>(
  CanteenLangNotifier.new,
);

/// Convenience derived provider: resolves the code to a [CanteenStrings] instance.
/// Screens watch this to get all translated strings.
final canteenL10nProvider = Provider<CanteenStrings>((ref) {
  final code = ref.watch(canteenLangProvider);
  return CanteenStrings.fromCode(code);
});
