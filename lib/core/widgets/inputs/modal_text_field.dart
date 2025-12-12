import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.minLines,
    this.maxLines,
    this.onChanged,
    this.alignLabelWithHint,
    this.inputFormatters,
    this.focusNode,
    this.errorText,
    this.prefix,
    this.prefixText,
    this.prefixStyle,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final bool? alignLabelWithHint;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final String? errorText;
  final Widget? prefix;
  final String? prefixText;
  final TextStyle? prefixStyle;

  @override
  State<ModalTextField> createState() => _ModalTextFieldState();
}

class _ModalTextFieldState extends State<ModalTextField> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant ModalTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (_ownsFocusNode && oldWidget.focusNode == null) {
        _focusNode.dispose();
      } else if (oldWidget.focusNode != null) {
        oldWidget.focusNode?.removeListener(_handleFocusChange);
      }
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() => setState(() {});
  void _handleControllerChange() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
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
      onChanged: widget.onChanged,
      minLines: widget.minLines,
      maxLines: widget.maxLines ?? (widget.minLines ?? 1),
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        errorText: widget.errorText,
        prefixText: widget.prefixText,
        prefixStyle: widget.prefixStyle ??
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(AppColors.black),
            ),
        alignLabelWithHint:
            widget.alignLabelWithHint ?? (widget.minLines != null),
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
