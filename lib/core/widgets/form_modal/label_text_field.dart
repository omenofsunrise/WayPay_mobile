import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waypay/core/theme/app_style.dart';

enum LabeledTextFieldFormat { plain, fullName, passport }

class LabeledTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final Widget? prefix;
  final LabeledTextFieldFormat format;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
    this.prefix,
    this.format = LabeledTextFieldFormat.plain,
  });

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  bool _isFormatting = false;

  @override
  void initState() {
    super.initState();
    if (widget.format != LabeledTextFieldFormat.plain) {
      widget.controller.addListener(_formatInput);
    }
  }

  @override
  void dispose() {
    if (widget.format != LabeledTextFieldFormat.plain) {
      widget.controller.removeListener(_formatInput);
    }
    super.dispose();
  }

  void _formatInput() {
    if (_isFormatting) return;
    _isFormatting = true;

    String originalText = widget.controller.text;
    TextSelection selection = widget.controller.selection;

    String newText = originalText;

    switch (widget.format) {
      case LabeledTextFieldFormat.fullName:
        newText = _formatFullName(originalText);
        break;
      case LabeledTextFieldFormat.passport:
        newText = _formatPassport(originalText);
        break;
      case LabeledTextFieldFormat.plain:
        break;
    }

    if (newText != originalText) {
      int baseOffset = selection.baseOffset;
      if (baseOffset == originalText.length) {
        baseOffset = newText.length;
      } else {
        baseOffset = baseOffset.clamp(0, newText.length);
      }

      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: baseOffset),
      );
    }

    _isFormatting = false;
  }

  String _formatFullName(String text) {
    final words = text.split(' ');
    final limitedWords = words.take(3).toList();

    List<String> processedWords = [];

    for (var word in limitedWords) {
      if (word.isEmpty) {
        processedWords.add('');
        continue;
      }
      final parts = word.split('-');
      final limitedParts = parts.take(2).toList();

      final formattedParts = limitedParts.map((part) {
        if (part.isEmpty) return '';
        return part[0].toUpperCase() + (part.length > 1 ? part.substring(1).toLowerCase() : '');
      }).toList();

      processedWords.add(formattedParts.join('-'));
    }

    return processedWords.join(' ');
  }

  String _formatPassport(String text) {
    final onlyDigits = text.replaceAll(RegExp(r'\D'), '');
    final digits = onlyDigits.length > 10 ? onlyDigits.substring(0, 10) : onlyDigits;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 4) buffer.write(' ');
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: AppStyle.medium16.copyWith(color: Colors.black87, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            inputFormatters:
                widget.inputFormatters ??
                () {
                  switch (widget.format) {
                    case LabeledTextFieldFormat.passport:
                      return [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)];
                    case LabeledTextFieldFormat.fullName:
                      return [
                        FilteringTextInputFormatter.allow(RegExp(r"[А-Яа-яA-Za-zёЁ \-]")),
                        LengthLimitingTextInputFormatter(100),
                      ];
                    case LabeledTextFieldFormat.plain:
                      return null;
                  }
                }(),

            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.label,
              errorText: widget.errorText,
              prefix: widget.prefix,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
