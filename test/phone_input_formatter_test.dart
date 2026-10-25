import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay_mobile/core/utils/phone_input_formatter.dart';

MaskTextInputFormatter _mask([String mask = ' (###) ###-##-##']) =>
    MaskTextInputFormatter(mask: mask, filter: {'#': RegExp(r'\d')});

TextEditingValue _value(String text, [int? cursor]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

/// Вставка [pasted] в поле с текстом [current] на место курсора.
TextEditingValue _paste(
  RussianPhoneInputFormatter f,
  TextEditingValue current,
  String pasted,
) {
  final sel = current.selection.isValid
      ? current.selection
      : TextSelection.collapsed(offset: current.text.length);
  final text = current.text.replaceRange(sel.start, sel.end, pasted);
  return f.formatEditUpdate(
    current,
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: sel.start + pasted.length),
    ),
  );
}

/// Ввод цифр по одной, как с клавиатуры.
TextEditingValue _type(RussianPhoneInputFormatter f, String digits) {
  var value = TextEditingValue.empty;
  for (final ch in digits.split('')) {
    value = f.formatEditUpdate(value, _value(value.text + ch));
  }
  return value;
}

void main() {
  group('extractRussianNationalDigits', () {
    test('убирает 8, 7 и +7 спереди', () {
      expect(extractRussianNationalDigits('89991234567'), '9991234567');
      expect(extractRussianNationalDigits('79991234567'), '9991234567');
      expect(extractRussianNationalDigits('+7 (999) 123-45-67'), '9991234567');
      expect(extractRussianNationalDigits('8 999 123 45 67'), '9991234567');
      expect(extractRussianNationalDigits('9991234567'), '9991234567');
    });

    test('не трогает то, что не похоже на целый номер', () {
      expect(extractRussianNationalDigits('999123'), isNull);
      expect(extractRussianNationalDigits('99991234567'), isNull);
      expect(extractRussianNationalDigits('123456789012'), isNull);
    });
  });

  group('RussianPhoneInputFormatter: вставка', () {
    for (final pasted in [
      '89991234567',
      '79991234567',
      '+79991234567',
      '+7 (999) 123-45-67',
      '8 (999) 123-45-67',
      '9991234567',
    ]) {
      test('«$pasted» в пустое поле', () {
        final mask = _mask();
        final f = RussianPhoneInputFormatter(mask);
        final result = _paste(f, TextEditingValue.empty, pasted);
        expect(result.text, ' (999) 123-45-67');
        expect(mask.getUnmaskedText(), '9991234567');
        expect(result.selection.baseOffset, result.text.length);
      });
    }

    test('вставка заменяет уже введённый номер', () {
      final mask = _mask();
      final f = RussianPhoneInputFormatter(mask);
      final typed = _type(f, '9001112233');
      expect(mask.getUnmaskedText(), '9001112233');

      final result = _paste(f, typed, '89991234567');
      expect(result.text, ' (999) 123-45-67');
      expect(mask.getUnmaskedText(), '9991234567');
    });

    test('вставка поверх выделенного текста', () {
      final mask = _mask();
      final f = RussianPhoneInputFormatter(mask);
      final typed = _type(f, '900');
      final selected = typed.copyWith(
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: typed.text.length,
        ),
      );
      final result = _paste(f, selected, '+7 999 123-45-67');
      expect(result.text, ' (999) 123-45-67');
      expect(mask.getUnmaskedText(), '9991234567');
    });

    test('маска с +7 в самой маске (добавление сотрудника)', () {
      final mask = _mask('+7 (###) ###-##-##');
      final f = RussianPhoneInputFormatter(mask);
      final result = _paste(f, TextEditingValue.empty, '+7 (999) 123-45-67');
      expect(result.text, '+7 (999) 123-45-67');
      expect(mask.getUnmaskedText(), '9991234567');
    });
  });

  group('RussianPhoneInputFormatter: обычный ввод', () {
    test('номер, начинающийся с 8, набирается как есть', () {
      final mask = _mask();
      final f = RussianPhoneInputFormatter(mask);
      final result = _type(f, '8121234567');
      expect(result.text, ' (812) 123-45-67');
      expect(mask.getUnmaskedText(), '8121234567');
    });

    test('лишняя цифра после полного номера не сдвигает номер', () {
      final mask = _mask();
      final f = RussianPhoneInputFormatter(mask);
      final typed = _type(f, '8121234567');
      final result = f.formatEditUpdate(typed, _value('${typed.text}9'));
      expect(mask.getUnmaskedText(), '8121234567');
      expect(result.text, ' (812) 123-45-67');
    });

    test('стирание последней цифры', () {
      final mask = _mask();
      final f = RussianPhoneInputFormatter(mask);
      final typed = _type(f, '9991234567');
      final text = typed.text.substring(0, typed.text.length - 1);
      f.formatEditUpdate(typed, _value(text));
      expect(mask.getUnmaskedText(), '999123456');
    });
  });

  testWidgets('вставка из буфера в настоящее поле', (tester) async {
    final mask = _mask();
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [RussianPhoneInputFormatter(mask)],
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.updateEditingValue(_value('89991234567'));
    await tester.pump();

    expect(controller.text, ' (999) 123-45-67');
    expect(mask.getUnmaskedText(), '9991234567');
  });
}
