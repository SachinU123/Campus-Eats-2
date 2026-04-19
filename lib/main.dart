import 'dart:developer' as dev;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/app/app.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/data/repositories/cart_repository.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/data/repositories/theme_repository.dart';
import 'package:campus_eats_ag/core/l10n/canteen_language_provider.dart';
import 'package:campus_eats_ag/core/services/notification_service.dart';
import 'package:campus_eats_ag/core/services/thermal_printer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Create the container to init repositories
  final container = ProviderContainer();

  // Initialize auth (load persisted session)
  await container.read(authRepositoryProvider).init();

  // Init theme
  await container.read(themeProvider.notifier).load();

  // Init canteen language preference (Phase 9)
  await container.read(canteenLangProvider.notifier).load();

  // Load cart from local storage
  await container.read(cartProvider.notifier).load();

  // Load orders on startup only if a session was already restored.
  // Skip when user is not logged in — avoids a noisy GET /orders/my → 401
  // in backend logs on every cold start. The orders screen loads them on demand.
  final restoredUser = container.read(authRepositoryProvider).currentUser;
  if (restoredUser != null &&
      (restoredUser.role == 'student' || restoredUser.role == 'faculty')) {
    await container.read(orderProvider.notifier).load();
  }

  // Phase 11: Load paired thermal printer preference
  await ThermalPrinterService.instance.load();

  // Phase 11: Initialise push notifications.
  // Needs the auth repo and api client to register the FCM token with the backend.
  // Runs after auth init so the token can be sent with a valid JWT.
  final authRepo = container.read(authRepositoryProvider);
  final apiClient = container.read(apiClientProvider);
  await NotificationService.instance.init(
    onTokenRefresh: (token) async {
      // Only register if the user is already logged in as student or faculty.
      // Canteen staff do not need push notifications.
      final user = authRepo.currentUser;
      if (user == null) return;
      if (user.role != 'student' && user.role != 'faculty') return;
      // Fire and forget — token registration failure must not block startup
      await apiClient.post('/orders/fcm-token', body: {'token': token});
    },
  );

  // ── Phase 11: Firebase Crashlytics ────────────────────────────────────────
  // Wired after Firebase.initializeApp() (called inside NotificationService.init).
  // Passes all Flutter framework errors + uncaught Dart errors to Crashlytics.
  // Safe to run in debug (reports, but Crashlytics dashboard filters debug builds).
  try {
    // Route Flutter framework errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Route uncaught async errors (Zone errors) to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // In debug mode, disable Crashlytics uploads to avoid polluting production data
    // (still captures locally). In release mode, enable.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

    dev.log('[Crashlytics] Wired — collection: ${!kDebugMode}', name: 'Main');
  } catch (e) {
    // Crashlytics init must never crash the app
    dev.log('[Crashlytics] Init failed (Firebase not configured?): $e', name: 'Main');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CampusEatsApp(),
    ),
  );
}
