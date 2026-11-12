import 'package:waypay_mobile/blacklist_plus/assets/resources.dart';
import 'package:waypay_mobile/blacklist_plus/core/di/dependency_injection.dart';
import 'package:waypay_mobile/blacklist_plus/core/utils/bottom_nav_controller.dart';
import 'package:waypay_mobile/blacklist_plus/core/utils/moderation_utils.dart';
import 'package:waypay_mobile/blacklist_plus/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late final Future<bool> _showCalculatorFuture;

  static const _navConfigs = [
    _NavItemConfig(icon: SvgIcons.calculator, branchIndex: 0),
    _NavItemConfig(icon: SvgIcons.notebook, branchIndex: 1),
    _NavItemConfig(icon: SvgIcons.bell, branchIndex: 2),
    _NavItemConfig(icon: SvgIcons.users, branchIndex: 3),
  ];

  @override
  void initState() {
    super.initState();
    _showCalculatorFuture = _loadCalculatorVisibility();
  }

  Future<bool> _loadCalculatorVisibility() async {
    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      final results = await Future.wait([
        authDataSource.getAuthInfo(),
        authDataSource.hasActiveSubscription(),
      ]);
      final authInfo = results[0] as Map<String, dynamic>;
      final hasActive = results[1] as bool;
      return isUserModerated(authInfo) && hasActive;
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: BottomNavController.instance,
        builder: (context, visible, _) {
          if (!visible) return const SizedBox.shrink();
          return FutureBuilder<bool>(
            future: _showCalculatorFuture,
            builder: (context, snapshot) {
              final showCalculator = snapshot.data ?? true;
              final items = showCalculator
                  ? _navConfigs
                  : _navConfigs.where((item) => item.branchIndex != 0).toList();
              final currentUiIndex = items.indexWhere(
                (item) => item.branchIndex == navigationShell.currentIndex,
              );

              return BottomNavBar(
                currentIndex: currentUiIndex < 0 ? 0 : currentUiIndex,
                items: items
                    .map((item) => BottomNavItem(icon: item.icon))
                    .toList(),
                onTap: (index) {
                  final branchIndex = items[index].branchIndex;
                  navigationShell.goBranch(
                    branchIndex,
                    initialLocation:
                        branchIndex == navigationShell.currentIndex,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NavItemConfig {
  const _NavItemConfig({required this.icon, required this.branchIndex});

  final String icon;
  final int branchIndex;
}
