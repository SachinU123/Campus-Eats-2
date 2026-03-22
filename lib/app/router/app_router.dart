import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/features/auth/login_screen.dart';
import 'package:campus_eats_ag/features/auth/register_screen.dart';
import 'package:campus_eats_ag/features/auth/canteen_phone_screen.dart';
import 'package:campus_eats_ag/features/auth/canteen_otp_screen.dart';
import 'package:campus_eats_ag/features/student/student_shell.dart';
import 'package:campus_eats_ag/features/student/home/student_home_screen.dart';
import 'package:campus_eats_ag/features/student/menu/menu_screen.dart';
import 'package:campus_eats_ag/features/student/menu/menu_item_detail_screen.dart';
import 'package:campus_eats_ag/features/student/cart/cart_screen.dart';
import 'package:campus_eats_ag/features/student/orders/student_orders_screen.dart';
import 'package:campus_eats_ag/features/student/orders/order_detail_screen.dart';
import 'package:campus_eats_ag/features/student/profile/student_profile_screen.dart';
import 'package:campus_eats_ag/features/student/payment/payment_screen.dart';
import 'package:campus_eats_ag/features/student/payment/order_success_screen.dart';
import 'package:campus_eats_ag/features/canteen/canteen_shell.dart';
import 'package:campus_eats_ag/features/canteen/verify/canteen_verify_screen.dart';
import 'package:campus_eats_ag/features/canteen/orders/canteen_orders_screen.dart';
import 'package:campus_eats_ag/features/canteen/reports/canteen_reports_screen.dart';
import 'package:campus_eats_ag/features/canteen/profile/canteen_profile_screen.dart';
import 'package:campus_eats_ag/models/menu_item.dart';
import 'package:campus_eats_ag/models/order.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _studentShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'studentShell');
final _canteenShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'canteenShell');

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: _resolveInitial(auth?.role),
    redirect: (context, state) {
      final user = ref.read(authProvider);
      final loc = state.matchedLocation;

      // Paths that do not require authentication
      final isPublicPath = loc == '/login' ||
          loc == '/register' ||
          loc == '/canteen-login' ||
          loc.startsWith('/canteen-otp');

      // Not logged in → send to login (unless already on a public path)
      if (user == null && !isPublicPath) return '/login';

      // Logged in → don't let them see auth screens
      if (user != null && isPublicPath) {
        return user.role == 'canteen' ? '/canteen' : '/student';
      }

      // Logged-in canteen trying to access student area → redirect
      if (user != null && user.role == 'canteen' && loc.startsWith('/student')) {
        return '/canteen';
      }

      // Logged-in student trying to access canteen area → redirect
      if (user != null && user.role == 'student' && loc.startsWith('/canteen')) {
        return '/student';
      }

      return null;
    },
    routes: [
      // ── Auth routes (public) ─────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Canteen phone entry (step 1 of canteen auth)
      GoRoute(
        path: '/canteen-login',
        builder: (context, state) => const CanteenPhoneScreen(),
      ),

      // Canteen OTP verification (step 2 of canteen auth)
      GoRoute(
        path: '/canteen-otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return CanteenOtpScreen(phoneNumber: phone);
        },
      ),

      // ── Student shell ────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _studentShellKey,
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: '/student',
            builder: (context, state) => const StudentHomeScreen(),
          ),
          GoRoute(
            path: '/student/menu',
            builder: (context, state) {
              final category = state.uri.queryParameters['category'];
              return MenuScreen(initialCategory: category);
            },
          ),
          GoRoute(
            path: '/student/menu/item/:itemId',
            builder: (context, state) {
              final item = state.extra as MenuItem?;
              final itemId = state.pathParameters['itemId'] ?? '';
              return MenuItemDetailScreen(item: item, itemId: itemId);
            },
          ),
          GoRoute(
            path: '/student/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/student/orders',
            builder: (context, state) => const StudentOrdersScreen(),
          ),
          GoRoute(
            path: '/student/orders/:orderId',
            builder: (context, state) {
              final order = state.extra as Order?;
              final orderId = state.pathParameters['orderId'] ?? '';
              return OrderDetailScreen(order: order, orderId: orderId);
            },
          ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) => const StudentProfileScreen(),
          ),
          GoRoute(
            path: '/student/payment',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return PaymentScreen(extra: extra ?? {});
            },
          ),
          GoRoute(
            path: '/student/success',
            builder: (context, state) {
              final order = state.extra as Order;
              return OrderSuccessScreen(order: order);
            },
          ),
        ],
      ),

      // ── Canteen shell ────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _canteenShellKey,
        builder: (context, state, child) => CanteenShell(child: child),
        routes: [
          GoRoute(
            path: '/canteen',
            builder: (context, state) => const CanteenVerifyScreen(),
          ),
          GoRoute(
            path: '/canteen/orders',
            builder: (context, state) => const CanteenOrdersScreen(),
          ),
          GoRoute(
            path: '/canteen/reports',
            builder: (context, state) => const CanteenReportsScreen(),
          ),
          GoRoute(
            path: '/canteen/profile',
            builder: (context, state) => const CanteenProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

String _resolveInitial(String? role) {
  return switch (role) {
    'canteen' => '/canteen',
    'student' => '/student',
    _ => '/login',
  };
}
