import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/features/auth/presentation/bloc/auth_cubit.dart';

class WhatsAppConfirmationDialog extends StatefulWidget {
  const WhatsAppConfirmationDialog({
    super.key,
    required this.phone,
    required this.onConfirm,
  });

  final String phone;
  final Future<void> Function(String code) onConfirm;

  @override
  State<WhatsAppConfirmationDialog> createState() =>
      _WhatsAppConfirmationDialogState();
}

class _WhatsAppConfirmationDialogState
    extends State<WhatsAppConfirmationDialog> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final error = state is AuthError ? state.message : null;

        return Dialog(
          backgroundColor: const Color(AppColors.background),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Text(
                  'Подтверждение по WhatsApp',
                  style: AppStyle.semiBold20,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Введите код, отправленный в WhatsApp на номер',
                  style: AppStyle.medium16.copyWith(
                    color: const Color(AppColors.grey),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.phone,
                  style: AppStyle.inter(
                    size: 18,
                    weight: FontWeight.w700,
                    color: const Color(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  autofocus: true,
                  enabled: !isLoading,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: AppStyle.inter(size: 20, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Код из WhatsApp',
                    errorText: error,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(AppColors.primary),
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: isLoading ? null : (_) => _submit(),
                ),
                const SizedBox(height: 18),
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    child: DefaultButton(
                      text: 'Подтвердить',
                      isPrimary: true,
                      onPressed: _submit,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    widget.onConfirm(code);
  }
}
