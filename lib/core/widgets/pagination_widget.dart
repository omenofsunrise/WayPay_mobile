import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;
  final int visibleCount;
  final bool isCompact;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
    this.visibleCount = 5,
    this.isCompact = false,
  });

  double _heightForDistance(int d) {
    if (d <= 0) return isCompact ? 32 : 40;
    if (d == 1) return isCompact ? 28 : 36;
    if (d == 2) return isCompact ? 24 : 32;
    return isCompact ? 20 : 28;
  }

  double _minWidthForDigits(int digits, double height) {
    final factor = isCompact ? 0.8 : 1.0;
    switch (digits) {
      case 1:
        return math.max(28 * factor, height + 4);
      case 2:
        return math.max(36 * factor, height + 8);
      case 3:
        return math.max(44 * factor, height + 12);
      default:
        return math.max(54 * factor, height + 16);
    }
  }

  List<int> _windowPages() {
    int count = visibleCount;

    if (totalPages <= count) {
      return List<int>.generate(totalPages, (i) => i + 1);
    }

    final half = count ~/ 2;
    int start = math.max(1, currentPage - half);
    int end = start + count - 1;

    if (end > totalPages) {
      end = totalPages;
      start = end - count + 1;
    }

    return [for (int p = start; p <= end; p++) p];
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(AppColors.primary);
    final inactiveColor = Colors.grey.shade400;

    Widget pageChip(int page) {
      final selected = page == currentPage;
      final distance = (page - currentPage).abs();
      final h = _heightForDistance(distance);
      final digits = page.toString().length;
      final minW = _minWidthForDigits(digits, h);

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 6),
        child: Material(
          color: selected ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => onPageSelected(page),
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h, minWidth: minW),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 12),
                child: Center(
                  child: Text(
                    '$page',
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: currentPage > 1
              ? () => onPageSelected(currentPage - 1)
              : () {},
          child: Icon(
            Icons.chevron_left,
            size: 28,
            color: Color(AppColors.grey),
          ),
        ),
        ..._windowPages().map(pageChip),
        GestureDetector(
          onTap: currentPage < totalPages
              ? () => onPageSelected(currentPage + 1)
              : () {},
          child: Icon(
            Icons.chevron_right,
            size: 28,
            color: Color(AppColors.grey),
          ),
        ),
      ],
    );
  }
}
