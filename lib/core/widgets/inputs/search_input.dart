import 'package:flutter/material.dart';

class CustomSearchInput extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onClear;
  final bool showClearButton;
  final Color iconColor;
  final Color fillColor;
  final double borderRadius;

  const CustomSearchInput({
    super.key,
    this.controller,
    this.hintText = 'Поиск',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.showClearButton = false,
    this.iconColor = Colors.grey,
    this.fillColor = const Color(0xFFF5F5F5),
    this.borderRadius = 25.0,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.search, color: iconColor),
        suffixIcon: showClearButton
            ? IconButton(
                icon: Icon(Icons.clear, color: iconColor),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }
}
