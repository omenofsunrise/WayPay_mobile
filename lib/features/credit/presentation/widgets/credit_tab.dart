import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';

enum CreditTab {
  all('Все договоры', Icons.article),
  favourite('Важные', Icons.star_border),
  debtors('Должники', Icons.download_rounded),
  archived('В архиве', Icons.hourglass_empty);

  final String label;
  final IconData icon;
  const CreditTab(this.label, this.icon);
}

class CreditTabDropdown extends StatelessWidget {
  final CreditTab selectedTab;
  final void Function(CreditTab tab) onTabSelected;

  const CreditTabDropdown({super.key, required this.selectedTab, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CreditTab>(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: SizedBox(
        height: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(AppColors.borderColor)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getLabel(selectedTab),
                  style: AppStyle.manrope(size: 14, weight: FontWeight.w400, color: Colors.black),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.black),
              ],
            ),
          ),
        ),
      ),
      itemBuilder: (context) => [
        _buildTabItem(context, CreditTab.all, 'Все договоры'),
        _buildTabItem(context, CreditTab.favourite, 'Важные'),
        _buildTabItem(context, CreditTab.debtors, 'Должники'),
        _buildTabItem(context, CreditTab.archived, 'В архиве'),
      ],
    );
  }

  PopupMenuItem<CreditTab> _buildTabItem(BuildContext context, CreditTab tab, String label) {
    final isSelected = tab == selectedTab;
    return PopupMenuItem<CreditTab>(
      value: tab,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.pop(context);
          onTabSelected(tab);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? Colors.teal : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppStyle.manrope(size: 14, weight: FontWeight.w400, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLabel(CreditTab tab) {
    switch (tab) {
      case CreditTab.all:
        return 'Все договоры';
      case CreditTab.favourite:
        return 'Важные';
      case CreditTab.debtors:
        return 'Должники';
      case CreditTab.archived:
        return 'В архиве';
    }
  }
}
