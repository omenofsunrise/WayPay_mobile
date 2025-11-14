import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';

class SearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool enabled;
  final FocusNode? focusNode;

  const SearchField({
    super.key,
    this.controller,
    this.hintText = 'Поиск...',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(AppColors.uncomfPayment),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          SvgPicture.asset(SvgIcons.search, width: 18, height: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              enabled: enabled,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onTap: onTap,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppStyle.medium16.copyWith(
                  color: const Color(AppColors.uiBorder),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: AppStyle.medium16.copyWith(
                color: const Color(AppColors.uiBorder),
                fontWeight: FontWeight.w400,
              ),
              cursorColor: const Color(AppColors.primary),
            ),
          ),
          if (controller?.text.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  controller?.clear();
                  onChanged?.call('');
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(AppColors.background),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: const Color(AppColors.uiBorder),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
