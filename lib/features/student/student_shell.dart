import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/cart_repository.dart';
import 'package:campus_eats_ag/data/repositories/connectivity_repository.dart';

class StudentShell extends ConsumerWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  static final _tabs = [
    (path: '/student', icon: Icons.home_rounded, label: 'Home'),
    (path: '/student/menu', icon: Icons.restaurant_menu_rounded, label: 'Menu'),
    (path: '/student/cart', icon: Icons.shopping_bag_rounded, label: 'Cart'),
    (path: '/student/orders', icon: Icons.receipt_long_rounded, label: 'Orders'),
    (path: '/student/profile', icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final cartItems = ref.watch(cartProvider);
    final connectivity = ref.watch(connectivityProvider);
    final isOffline = connectivity == ConnectivityStatus.offline;

    int currentIndex = 0;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path) && _tabs[i].path != '/student' ||
          location == _tabs[i].path) {
        currentIndex = i;
      }
    }
    // fix home tab
    if (location == '/student') currentIndex = 0;

    final cartCount = cartItems.fold<int>(0, (s, i) => s + i.quantity);

    return Scaffold(
      body: Column(
        children: [
          if (isOffline) const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          context.go(_tabs[i].path);
        },
        destinations: _tabs.asMap().entries.map((e) {
          final tab = e.value;
          final isCart = tab.path == '/student/cart';
          return NavigationDestination(
            icon: isCart && cartCount > 0
                ? Badge.count(
                    count: cartCount,
                    child: Icon(tab.icon),
                  )
                : Icon(tab.icon),
            selectedIcon: isCart && cartCount > 0
                ? Badge.count(
                    count: cartCount,
                    child: Icon(tab.icon),
                  )
                : Icon(tab.icon),
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }
}
