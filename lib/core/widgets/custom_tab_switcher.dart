import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';

/// Custom tab switcher replicating the design used across client flows.
class CustomTabSwitcher extends StatelessWidget {
  const CustomTabSwitcher({
    super.key,
    required this.controller,
    required this.tabs,
  }) : assert(tabs.length > 0);

  final TabController controller;
  final List<String> tabs;

  static const _inactiveColor = Color(0xFFBCC1C8);
  static const _lineColor = Color(0xFFE5E5EA);
  static const _animDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    assert(
      controller.length == tabs.length,
      'Tabs count must match controller length',
    );
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final animationValue =
            controller.animation?.value ?? controller.index.toDouble();
        final activeIndex = animationValue.round().clamp(0, tabs.length - 1);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: List.generate(tabs.length, (index) {
                final bool isActive = activeIndex == index;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => controller.animateTo(index),
                    child: AnimatedDefaultTextStyle(
                      duration: _animDuration,
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? const Color(AppColors.primary)
                            : _inactiveColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Text(tabs[index], textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final indicatorWidth = tabs.isEmpty
                    ? 0.0
                    : totalWidth / tabs.length;
                final clampedValue = animationValue.clamp(0.0, tabs.length - 1);
                final left = indicatorWidth * clampedValue;
                return SizedBox(
                  height: 2,
                  child: Stack(
                    children: [
                      Positioned.fill(child: Container(color: _lineColor)),
                      AnimatedPositioned(
                        duration: _animDuration,
                        curve: Curves.easeInOut,
                        left: left,
                        width: indicatorWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(color: const Color(AppColors.primary)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
