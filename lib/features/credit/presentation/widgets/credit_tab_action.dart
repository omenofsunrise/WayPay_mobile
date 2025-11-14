import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_tab.dart';

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
      // Используем SVG иконку выбранной вкладки
      icon: SvgPicture.asset(
        selectedTab.iconPath,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(
          Color(AppColors.uiBorder),
          BlendMode.srcIn,
        ),
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
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
              // SVG иконка вкладки
              SvgPicture.asset(
                tab.iconPath,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
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
