import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';

class CustomInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool isDateField;
  final VoidCallback? onTap;
  final InputType inputType;

  const CustomInput({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.isDateField = false,
    this.onTap,
    this.inputType = InputType.text,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

enum InputType { text, fullname }

class _CustomInputState extends State<CustomInput> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (widget.inputType == InputType.fullname) {
      _formatFullName();
    }
  }

  void _formatFullName() {
    final text = widget.controller.text;

    String cleanedText = text.replaceAll(RegExp(r'[0-9]'), '');

    if (cleanedText.isNotEmpty) {
      final words = cleanedText.split(' ');
      final formattedWords = words.map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).toList();

      cleanedText = formattedWords.join(' ');
    }

    if (cleanedText != text) {
      widget.controller.value = widget.controller.value.copyWith(
        text: cleanedText,
        selection: TextSelection.collapsed(offset: cleanedText.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = widget.controller.text.isNotEmpty;
    final bool shouldShowLabel = _isFocused || hasText;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Focus(
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
        },
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.inputType == InputType.fullname
              ? TextInputType.text
              : widget.keyboardType,
          readOnly: widget.isDateField,
          onTap: widget.onTap,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Color(AppColors.lightGreyBackground),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(AppColors.primary), width: 2),
            ),
            labelText: widget.label,
            labelStyle: AppStyle.manrope(
              size: shouldShowLabel ? 12 : 14,
              weight: FontWeight.w400,
              color: shouldShowLabel ? Color(AppColors.black) : Colors.grey,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: null,
          ),
          style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
        ),
      ),
    );
  }
}
