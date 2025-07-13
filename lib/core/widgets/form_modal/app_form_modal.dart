import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/form_modal/form_field_config.dart';
import 'package:waypay/core/widgets/default_button.dart';

class AppFormModal extends StatelessWidget {
  final String title;
  final List<FormFieldConfig> fields;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String cancelText;
  final String saveText;

  const AppFormModal({
    super.key,
    required this.title,
    required this.fields,
    required this.onCancel,
    required this.onSave,
    this.cancelText = 'Отменить',
    this.saveText = 'Сохранить',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppStyle.medium20.copyWith(
                  color: Color(AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              ...fields.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (f.label != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            f.label!,
                            style: AppStyle.medium16.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      TextField(
                        controller: f.controller,
                        keyboardType: f.keyboardType,
                        obscureText: f.obscureText,
                        decoration: InputDecoration(
                          hintText: f.placeholder,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DefaultButton(
                      text: cancelText,
                      color: const Color(AppColors.greyLight),
                      onPressed: onCancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DefaultButton(
                      text: saveText,
                      color: const Color(AppColors.primary),
                      onPressed: onSave,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
