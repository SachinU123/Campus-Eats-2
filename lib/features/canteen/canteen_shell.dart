import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_ag/core/l10n/canteen_language_provider.dart';
import 'package:campus_eats_ag/core/widgets/shared_widgets.dart';
import 'package:campus_eats_ag/data/repositories/connectivity_repository.dart';

class CanteenShell extends ConsumerWidget {
  final Widget child;
  const CanteenShell({super.key, required this.child});

  static const _tabPaths = [
    '/canteen',
    '/canteen/orders',
    '/canteen/menu',
    '/canteen/reports',
    '/canteen/profile',
  ];

  static const _tabIcons = [
    Icons.qr_code_scanner_rounded,
    Icons.list_alt_rounded,
    Icons.menu_book_rounded,
    Icons.bar_chart_rounded,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final connectivity = ref.watch(connectivityProvider);
    final isOffline = connectivity == ConnectivityStatus.offline;
    final s = ref.watch(canteenL10nProvider);

    final tabLabels = [
      s.navVerify,
      s.navOrders,
      s.navMenu,
      s.navReports,
      s.navProfile,
    ];

    // Determine selected tab index
    int currentIndex = 0;
    for (int i = _tabPaths.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabPaths[i])) {
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
        onDestinationSelected: (i) => context.go(_tabPaths[i]),
        destinations: List.generate(
          _tabPaths.length,
          (i) => NavigationDestination(
            icon: Icon(_tabIcons[i]),
            label: tabLabels[i],
          ),
        ),
      ),
    );
  }
}
