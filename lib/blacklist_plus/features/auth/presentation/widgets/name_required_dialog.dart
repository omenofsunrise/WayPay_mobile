import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

Future<String?> showNameRequiredDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => const _NameRequiredDialog(),
  );
}

class _NameRequiredDialog extends StatefulWidget {
  const _NameRequiredDialog();

  @override
  State<_NameRequiredDialog> createState() => _NameRequiredDialogState();
}

class _NameRequiredDialogState extends State<_NameRequiredDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Введите ФИО');
      return;
    }
    setState(() => _submitting = true);
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_submitting && _controller.text.trim().isNotEmpty;
    return WayPayModal(
      title: 'Как вас зовут?',
      primaryText: 'Подтвердить',
      primaryEnabled: canSubmit,
      isSubmitting: _submitting,
      showCancelButton: false,
      onClose: () => Navigator.of(context).pop(),
      onPrimary: _submit,
      child: ModalTextField(
        controller: _controller,
        label: 'ФИО',
        hintText: 'Иванов Иван Иванович',
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
          setState(() {});
        },
        errorText: _error,
      ),
    );
  }
}
