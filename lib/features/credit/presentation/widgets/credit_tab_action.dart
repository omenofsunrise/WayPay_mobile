import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/features/credit/presentation/widgets/credit_tab.dart';

class CreditTabAppBarAction extends StatelessWidget {
  final CreditTab selectedTab;
  final ValueChanged<CreditTab> onSelected;

  const CreditTabAppBarAction({
    super.key,
    required this.selectedTab,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CreditTab>(
      tooltip: 'Выбрать вкладку',
      icon: const Icon(
        Icons.segment,
        color: Colors.white,
      ), // маленькая кнопка в AppBar
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      // БЕЗ иконок вкладок — только радио + текст
      itemBuilder: (context) => CreditTab.values.map((tab) {
        final isSelected = tab == selectedTab;
        return PopupMenuItem<CreditTab>(
          value: tab,
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? const Color(AppColors.primary)
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                tab.label,
                style: AppStyle.manrope(
                  size: 14,
                  weight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
