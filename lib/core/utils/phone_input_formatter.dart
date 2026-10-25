import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Достаёт 10 цифр российского номера без кода страны из вставленного текста.
/// Понимает «89991234567», «+7 (999) 123-45-67», «9991234567».
/// Если в тексте не номер целиком, возвращает null.
String? extractRussianNationalDigits(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) return digits;
  if (digits.length == 11 &&
      (digits.startsWith('7') || digits.startsWith('8'))) {
    return digits.substring(1);
  }
  return null;
}

/// Обёртка над маской телефона «(###) ###-##-##» с префиксом +7.
///
/// Маска сама по себе берёт первые 10 цифр вставленного текста, поэтому
/// «89991234567» превращается в «(899) 912-34-56». Здесь вставка целого
/// номера заменяет содержимое поля номером без 8/+7. Ввод по одной цифре
/// передаётся маске без изменений.
class RussianPhoneInputFormatter extends TextInputFormatter {
  RussianPhoneInputFormatter(this.mask);

  final MaskTextInputFormatter mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final inserted = _insertedText(oldValue, newValue);
    if (inserted.length > 1) {
      final national = extractRussianNationalDigits(inserted);
      if (national != null) {
        mask.clear();
        return mask.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: national,
            selection: TextSelection.collapsed(offset: national.length),
          ),
        );
      }
    }
    return mask.formatEditUpdate(oldValue, newValue);
  }

  /// Текст, который появился в поле на месте курсора или выделения.
  static String _insertedText(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final before = oldValue.text;
    final after = newValue.text;
    final sel = oldValue.selection;
    if (sel.isValid && sel.end <= before.length) {
      final kept = before.length - (sel.end - sel.start);
      final insertedLength = after.length - kept;
      if (insertedLength > 0 &&
          after.startsWith(before.substring(0, sel.start)) &&
          after.endsWith(before.substring(sel.end))) {
        return after.substring(sel.start, sel.start + insertedLength);
      }
    }
    // Запасной путь: всё, кроме общего начала и конца.
    var start = 0;
    while (start < before.length &&
        start < after.length &&
        before[start] == after[start]) {
      start++;
    }
    var endBefore = before.length;
    var endAfter = after.length;
    while (endBefore > start &&
        endAfter > start &&
        before[endBefore - 1] == after[endAfter - 1]) {
      endBefore--;
      endAfter--;
    }
    return after.substring(start, endAfter);
  }
}
