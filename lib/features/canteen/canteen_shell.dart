import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/connectivity_repository.dart';

class CanteenShell extends ConsumerWidget {
  final Widget child;
  const CanteenShell({super.key, required this.child});

  static const _tabs = [
    (path: '/canteen', icon: Icons.qr_code_scanner_rounded, label: 'Verify'),
    (path: '/canteen/orders', icon: Icons.list_alt_rounded, label: 'Orders'),
    (path: '/canteen/reports', icon: Icons.bar_chart_rounded, label: 'Reports'),
    (path: '/canteen/profile', icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final connectivity = ref.watch(connectivityProvider);
    final isOffline = connectivity == ConnectivityStatus.offline;

    // Determine selected tab index
    int currentIndex = 0;
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i].path)) {
        currentIndex = i;
        break;
      }
    }
    // Exact match for root canteen path
    if (location == '/canteen') currentIndex = 0;

    return Scaffold(
      body: Column(
        children: [
          if (isOffline) const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}
