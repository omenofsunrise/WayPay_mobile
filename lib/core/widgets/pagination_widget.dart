import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final double padding;
  final ValueChanged<int> onPageSelected;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
    this.padding = 8,
  });

  List<Widget> _buildPageButtons() {
    List<Widget> buttons = [];

    void addPageButton(int page) {
      final selected = page == currentPage;
      buttons.add(
        GestureDetector(
          onTap: () => onPageSelected(page),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: padding / 2),
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(AppColors.primary) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 16,
                color: selected ? Colors.white : Colors.black,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    void addEllipsis() {
      buttons.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Text('...', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        addPageButton(i);
      }
    } else {
      addPageButton(1);
      if (currentPage <= 3) {
        for (int i = 2; i <= 4; i++) {
          addPageButton(i);
        }
        addEllipsis();
        addPageButton(totalPages);
      } else if (currentPage >= totalPages - 2) {
        addEllipsis();
        for (int i = totalPages - 3; i <= totalPages; i++) {
          addPageButton(i);
        }
      } else {
        addEllipsis();
        for (int i = currentPage - 1; i <= currentPage + 1; i++) {
          addPageButton(i);
        }
        addEllipsis();
        addPageButton(totalPages);
      }
    }

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 1 ? () => onPageSelected(currentPage - 1) : null,
        ),
        ..._buildPageButtons(),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages ? () => onPageSelected(currentPage + 1) : null,
        ),
      ],
    );
  }
}
