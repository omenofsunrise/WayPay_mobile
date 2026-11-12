import 'package:waypay_mobile/blacklist_plus/assets/resources.dart';
import 'package:waypay_mobile/blacklist_plus/core/utils/bottom_nav_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _navConfigs = [
    _NavItemConfig(icon: SvgIcons.calculator, branchIndex: 0),
    _NavItemConfig(icon: SvgIcons.notebook, branchIndex: 1),
    _NavItemConfig(icon: SvgIcons.bell, branchIndex: 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: BottomNavController.instance,
        builder: (context, visible, _) {
          if (!visible) return const SizedBox.shrink();
          return BottomNavBar(
            currentIndex: navigationShell.currentIndex,
            items: _navConfigs
                .map((item) => BottomNavItem(icon: item.icon))
                .toList(),
            onTap: (index) {
              final branchIndex = _navConfigs[index].branchIndex;
              navigationShell.goBranch(
                branchIndex,
                initialLocation: branchIndex == navigationShell.currentIndex,
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
