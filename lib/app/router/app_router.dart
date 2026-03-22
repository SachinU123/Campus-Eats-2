import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_eats_ag/data/repositories/auth_repository.dart';
import 'package:campus_eats_ag/features/auth/login_screen.dart';
import 'package:campus_eats_ag/features/auth/register_screen.dart';
import 'package:campus_eats_ag/features/student/student_shell.dart';
import 'package:campus_eats_ag/features/student/home/student_home_screen.dart';
import 'package:campus_eats_ag/features/student/menu/menu_screen.dart';
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
import 'package:campus_eats_ag/models/order.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _studentShellKey = GlobalKey<NavigatorState>(debugLabel: 'studentShell');
final _canteenShellKey = GlobalKey<NavigatorState>(debugLabel: 'canteenShell');

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: auth == null ? '/login' : (auth.role == 'canteen' ? '/canteen' : '/student'),
    redirect: (context, state) {
      final user = ref.read(authProvider);
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (user == null && !onAuth) return '/login';
      if (user != null && onAuth) {
        return user.role == 'canteen' ? '/canteen' : '/student';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Student shell
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
            builder: (context, state) => const MenuScreen(),
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

      // Canteen shell
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
        ],
      ),
    ],
  );
});
