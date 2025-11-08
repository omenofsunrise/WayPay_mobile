import 'package:flutter/material.dart';
import 'package:waypay/assets/resources.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';

enum CreditTab {
  all('Все договоры', SvgIcons.allCredits),
  favourite('Важные', SvgIcons.importantCredits),
  debtors('Должники', SvgIcons.debtCredits),
  archived('В архиве', SvgIcons.inactiveCredits);

  final String label;
  final String iconPath;

  const CreditTab(this.label, this.iconPath);
}

class CreditTabDropdown extends StatelessWidget {
  final CreditTab selectedTab;
  final void Function(CreditTab tab) onTabSelected;

  const CreditTabDropdown({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

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
                // Иконка выбранного раздела - используем SvgIcon
                SvgIcon(
                  assetPath: selectedTab.iconPath,
                  width: 20,
                  height: 20,
                  color: Colors.black,
                ),
                const SizedBox(width: 6),
                Text(
                  selectedTab.label, // Используем свойство label напрямую
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.black),
              ],
            ),
          ),
        ),
      ),
      itemBuilder: (context) => [
        _buildTabItem(context, CreditTab.all),
        _buildTabItem(context, CreditTab.favourite),
        _buildTabItem(context, CreditTab.debtors),
        _buildTabItem(context, CreditTab.archived),
      ],
      onSelected: onTabSelected,
    );
  }

  PopupMenuItem<CreditTab> _buildTabItem(BuildContext context, CreditTab tab) {
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
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? Colors.teal : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              // Иконка вкладки - используем SvgIcon
              SvgIcon(
                assetPath: tab.iconPath,
                width: 20,
                height: 20,
                color: Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: AppStyle.manrope(
                  size: 14,
                  weight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
