import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';

class ModalTextField extends StatefulWidget {
  const ModalTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.suffixIconConstraints,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;

  @override
  State<ModalTextField> createState() => _ModalTextFieldState();
}

class _ModalTextFieldState extends State<ModalTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant ModalTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
    }
  }

  void _handleFocusChange() => setState(() {});
  void _handleControllerChange() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.trim().isNotEmpty;
    final isActive = _focusNode.hasFocus || hasValue;
    const inactiveColor = Color(0xFFD9DDE5);
    const activeColor = Color(AppColors.primary);

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1.5),
    );

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        suffixIcon: widget.suffixIcon,
        suffixIconConstraints: widget.suffixIconConstraints ??
            const BoxConstraints(
              minHeight: 24,
              minWidth: 24,
              maxHeight: 28,
              maxWidth: 28,
            ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? activeColor : const Color(0xFF9CA3AF),
        ),
        border: border(isActive ? activeColor : inactiveColor),
        enabledBorder: border(isActive ? activeColor : inactiveColor),
        focusedBorder: border(activeColor),
      ),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(AppColors.black),
      ),
      cursorColor: activeColor,
    );
  }
}
