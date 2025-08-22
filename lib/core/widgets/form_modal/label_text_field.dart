import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';

enum LabeledTextFieldFormat {
  plain,
  fullName,
  passport,
  phone,
  birthdate,
  amount,
}

class LabeledTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final Widget? prefix;
  final String? hintText;
  final LabeledTextFieldFormat format;
  final bool enabled;

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
    this.enabled = true,
    this.hintText,
  });

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  bool _isFormatting = false;

  // Телефон: маска БЕЗ начальной "8", её показывайте через prefix/prefixText
  late final MaskTextInputFormatter maskFormatter = MaskTextInputFormatter(
    mask: '(###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    initialText: widget.controller.text.replaceAll(RegExp(r'^[87]'), ''),
  );

  final _birthdateFormatter = MaskTextInputFormatter(
    mask: '##.##.####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    // Листенер оставляем только для ФИО, паспорт теперь форматируется через TextInputFormatter
    if (widget.format == LabeledTextFieldFormat.fullName) {
      widget.controller.addListener(_formatInput);
    }
  }

  @override
  void dispose() {
    if (widget.format == LabeledTextFieldFormat.fullName) {
      widget.controller.removeListener(_formatInput);
    }
    super.dispose();
  }

  void _formatInput() {
    if (_isFormatting) return;
    _isFormatting = true;

    final originalText = widget.controller.text;
    String newText = originalText;

    if (widget.format == LabeledTextFieldFormat.fullName) {
      newText = _formatFullName(originalText);
    }

    if (newText != originalText) {
      final selection = widget.controller.selection;
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset.clamp(0, newText.length),
        ),
      );
    }

    _isFormatting = false;
  }

  String _formatFullName(String text) {
    final words = text.split(' ').take(3).toList();
    return words
        .map((word) {
          final parts = word.split('-').take(2).toList();
          return parts
              .map((part) {
                if (part.isEmpty) return '';
                return part[0].toUpperCase() +
                    (part.length > 1 ? part.substring(1).toLowerCase() : '');
              })
              .join('-');
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    List<TextInputFormatter>? formatters = widget.inputFormatters;

    if (formatters == null) {
      switch (widget.format) {
        case LabeledTextFieldFormat.passport:
          // 10 цифр, пробел после 4-й: "9999 999999"
          formatters = [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(
              10,
            ), // только цифры, пробел добавит форматтер
            PassportInputFormatter(),
          ];
          break;

        case LabeledTextFieldFormat.fullName:
          formatters = [
            FilteringTextInputFormatter.allow(RegExp(r"[А-Яа-яA-Za-zёЁ \-]")),
            LengthLimitingTextInputFormatter(100),
          ];
          break;

        case LabeledTextFieldFormat.phone:
          formatters = [FilteringTextInputFormatter.digitsOnly, maskFormatter];
          break;

        case LabeledTextFieldFormat.birthdate:
          formatters = [_birthdateFormatter];
          break;

        case LabeledTextFieldFormat.amount:
          formatters = const [ThousandsSeparatorInputFormatter()];
          break;

        case LabeledTextFieldFormat.plain:
          formatters = null;
          break;
      }
    }

    final effectiveKeyboardType =
        widget.format == LabeledTextFieldFormat.amount ||
            widget.format == LabeledTextFieldFormat.passport ||
            widget.format == LabeledTextFieldFormat.phone ||
            widget.format == LabeledTextFieldFormat.birthdate
        ? const TextInputType.numberWithOptions(signed: false, decimal: false)
        : widget.keyboardType;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty)
            Column(
              children: [
                Text(
                  widget.label,
                  style: AppStyle.medium16.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          TextField(
            enabled: widget.enabled,
            controller: widget.controller,
            keyboardType: effectiveKeyboardType,
            inputFormatters: formatters,
            onChanged: widget.onChanged,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefix: widget.prefix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(AppColors.primary)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Color(AppColors.primary),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              errorText: widget.errorText,
            ),
            style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

/// Паспорт: добавляет пробел после 4-й цифры и корректно позиционирует курсор.
/// Вводим только цифры, формат: "9999 999999"
class PassportInputFormatter extends TextInputFormatter {
  const PassportInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldV,
    TextEditingValue newV,
  ) {
    // 1) оставляем только цифры, максимум 10
    final raw = newV.text.replaceAll(RegExp(r'\D'), '');
    final digits = raw.length <= 10 ? raw : raw.substring(0, 10);

    // 2) формат: 4 цифры + пробел + оставшиеся
    String formatted;
    if (digits.length <= 4) {
      formatted = digits;
    } else {
      formatted = '${digits.substring(0, 4)} ${digits.substring(4)}';
    }

    // 3) пересчитываем позицию курсора: сколько цифр было слева от старого курсора
    final beforeCursor = (newV.selection.baseOffset <= 0)
        ? 0
        : RegExp(r'\d')
              .allMatches(
                newV.text.substring(
                  0,
                  newV.selection.baseOffset.clamp(0, newV.text.length),
                ),
              )
              .length;

    // 4) находим позицию в formatted, соответствующую beforeCursor-й цифре
    int cursor = 0;
    int seenDigits = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (_isDigit(formatted.codeUnitAt(i))) {
        seenDigits++;
        if (seenDigits == beforeCursor) {
          cursor = i + 1;
          break;
        }
      }
    }
    // если курсор должен быть в конце
    if (beforeCursor == 0) {
      cursor = 0;
    } else if (seenDigits < beforeCursor) {
      cursor = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  bool _isDigit(int cu) => cu >= 48 && cu <= 57;
}

/// Безопасный форматтер "30 050 000": группировка по 3 цифры справа, без int.parse
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldV,
    TextEditingValue newV,
  ) {
    final digits = newV.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _groupThousands(digits);

    final beforeCursor = (newV.selection.baseOffset <= 0)
        ? 0
        : RegExp(r'\d')
              .allMatches(
                newV.text.substring(
                  0,
                  newV.selection.baseOffset.clamp(0, newV.text.length),
                ),
              )
              .length;

    int cursor = 0, seenDigits = 0;
    for (int i = 0; i < formatted.length; i++) {
      final ch = formatted.codeUnitAt(i);
      if (ch >= 48 && ch <= 57) {
        seenDigits++;
        if (seenDigits == beforeCursor) {
          cursor = i + 1;
          break;
        }
      }
    }
    if (beforeCursor == 0) cursor = 0;
    if (seenDigits < beforeCursor) cursor = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  String _groupThousands(String digits) {
    final buf = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      buf.write(digits[i]);
      count++;
      if (count % 3 == 0 && i != 0) buf.write(' ');
    }
    final reversed = buf.toString();
    return String.fromCharCodes(reversed.runes.toList().reversed);
  }
}
