import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/assets/resources.dart';
import 'package:waypay/core/theme/app_colors.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  List<BottomNavigationBarItem> get _bottomNavItemsCustom {
    return [
      BottomNavigationBarItem(
        icon: _buildNavIcon(SvgIcons.home, isActive: false),
        activeIcon: _buildNavIcon(SvgIcons.home, isActive: true),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(SvgIcons.todo, isActive: false),
        activeIcon: _buildNavIcon(SvgIcons.todo, isActive: true),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(SvgIcons.chat, isActive: false),
        activeIcon: _buildNavIcon(SvgIcons.chat, isActive: true),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(SvgIcons.newCredit, isActive: false),
        activeIcon: _buildNavIcon(SvgIcons.newCredit, isActive: true),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(SvgIcons.blog, isActive: false),
        activeIcon: _buildNavIcon(SvgIcons.blog, isActive: true),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(SvgIcons.calculator, isActive: false),
        activeIcon: _buildNavIcon(SvgIcons.calculator, isActive: true),
        label: '',
      ),
    ];
  }

  Widget _buildNavIcon(
    String assetPath, {
    required bool isActive,
    double size = 24.0,
  }) {
    if (!isActive) {
      return _buildSvgIcon(assetPath, isActive: false, size: size);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(AppColors.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: _buildSvgIcon(assetPath, isActive: true, size: size),
      ),
    );
  }

  Widget _buildSvgIcon(
    String assetPath, {
    required bool isActive,
    double size = 24.0,
  }) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        isActive
            ? const Color(AppColors.white)
            : const Color(AppColors.darkGrey),
        BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        items: _bottomNavItemsCustom,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(AppColors.white),
        unselectedItemColor: const Color(AppColors.darkGrey),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor: const Color(AppColors.white),
        elevation: 8.0,
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
