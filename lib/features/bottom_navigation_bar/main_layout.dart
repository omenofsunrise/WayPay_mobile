import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/utils/bottom_nav_controller.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _navConfigs = [
    _NavItemConfig(icon: SvgIcons.home),
    _NavItemConfig(icon: SvgIcons.todo),
    _NavItemConfig(icon: SvgIcons.chat),
    _NavItemConfig(icon: SvgIcons.add, activeIcon: SvgIcons.add),
    _NavItemConfig(icon: SvgIcons.blog),
    _NavItemConfig(icon: SvgIcons.calculator),
  ];
  static const _newCreditPaths = {
    '/new_credit_details_screen',
    '/new_credit_products_screen',
    '/new_credit_schedules_screen',
  };

  @override
  Widget build(BuildContext context) {
    final locationPath = GoRouterState.of(context).uri.path;
    final highlightedIndex = _newCreditPaths.contains(locationPath)
        ? 3
        : navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: BottomNavController.instance,
        builder: (context, visible, _) {
          if (!visible) return const SizedBox.shrink();
          return _AppBottomNavBar(
            currentIndex: highlightedIndex,
            items: _navConfigs,
            onTap: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          );
        },
      ),
    );
  }
}

class _AppBottomNavBar extends StatelessWidget {
  const _AppBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItemConfig> items;

  static const _barBg = Color(AppColors.white);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: _barBg,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: _barBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top: BorderSide(
              color: Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final config = items[index];
            final selected = currentIndex == index;
            return _NavItem(
              icon: selected ? config.activeIcon ?? config.icon : config.icon,
              selected: selected,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final bool selected;
  final VoidCallback onTap;

  static const _brand = Color(AppColors.primary);
  static const _iconColor = Color(AppColors.uiBorder);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 56,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _brand : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: SvgPicture.asset(
          icon,
          width: 26,
          height: 26,
          colorFilter: ColorFilter.mode(
            selected ? const Color(AppColors.white) : _iconColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _NavItemConfig {
  const _NavItemConfig({required this.icon, this.activeIcon});

  final String icon;
  final String? activeIcon;
}
