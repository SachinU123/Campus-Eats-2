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
import 'package:campus_eats_ag/features/canteen/menu/canteen_menu_manage_screen.dart';
import 'package:campus_eats_ag/features/canteen/reports/canteen_reports_screen.dart';
import 'package:campus_eats_ag/features/canteen/profile/canteen_profile_screen.dart';
// Phase 7: Admin shell and screens
import 'package:campus_eats_ag/features/admin/admin_shell.dart';
import 'package:campus_eats_ag/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:campus_eats_ag/features/admin/menu/admin_menu_screen.dart';
import 'package:campus_eats_ag/features/admin/staff/admin_staff_screen.dart';
import 'package:campus_eats_ag/models/menu_item.dart';
import 'package:campus_eats_ag/models/order.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _studentShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'studentShell');
final _canteenShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'canteenShell');
final _adminShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'adminShell');

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: _resolveInitial(auth),
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
        return _resolveInitial(user);
      }

      final isAdmin = user != null && user.isAdmin;
      final isCanteen = user != null && user.role == 'canteen';
      final isCustomer = user != null &&
          (user.role == 'student' || user.role == 'faculty');

      // Phase 7: admin routes to /admin shell
      if (isAdmin) {
        // Admin should not go to /canteen or /student
        if (loc.startsWith('/canteen') || loc.startsWith('/student')) {
          return '/admin';
        }
        return null;
      }

      // Regular canteen staff: cannot access /student or /admin
      if (isCanteen) {
        if (loc.startsWith('/student') || loc.startsWith('/admin')) {
          return '/canteen';
        }
        return null;
      }

      // Student/faculty: cannot access /canteen or /admin
      if (isCustomer) {
        if (loc.startsWith('/canteen') || loc.startsWith('/admin')) {
          return '/student';
        }
        return null;
      }

      return null;
    },
    routes: [
      // ── Auth routes (public) ──────────────────────────────────────────
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

      // ── Student shell ─────────────────────────────────────────────────
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

      // ── Canteen shell (regular staff) ─────────────────────────────────
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
            path: '/canteen/menu',
            builder: (context, state) => const CanteenMenuManageScreen(),
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

      // ── Admin shell (Phase 7) ─────────────────────────────────────────
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/menu',
            builder: (context, state) => const AdminMenuScreen(),
          ),
          GoRoute(
            path: '/admin/staff',
            builder: (context, state) => const AdminStaffScreen(),
          ),
        ],
      ),
    ],
  );
});

String _resolveInitial(dynamic userOrRole) {
  final String? role;
  final bool isAdmin;
  if (userOrRole is String?) {
    role = userOrRole;
    isAdmin = false;
  } else {
    // UserProfile
    final u = userOrRole;
    role = u?.role as String?;
    isAdmin = u?.isAdmin as bool? ?? false;
  }
  if (isAdmin) return '/admin';
  return switch (role) {
    'canteen' => '/canteen',
    'student' => '/student',
    'faculty' => '/student',
    _ => '/login',
  };
}
