import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/app/app.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/data/repositories/cart_repository.dart';
import 'package:campus_eats_ag/data/repositories/order_repository.dart';
import 'package:campus_eats_ag/data/repositories/theme_repository.dart';

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

  // Load cart from local storage
  await container.read(cartProvider.notifier).load();

  // Load orders
  await container.read(orderProvider.notifier).load();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CampusEatsApp(),
    ),
  );
}
