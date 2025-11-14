import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay_mobile/core/widgets/helpers.dart';
import 'package:waypay_mobile/features/admin_panel/data/models/company_model.dart';
import 'package:waypay_mobile/features/admin_panel/presentation/cubit/company_cubit.dart';

class CompanyCard extends StatefulWidget {
  final CompanyModel company;
  const CompanyCard({super.key, required this.company});

  @override
  State<CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends State<CompanyCard> {
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Изменить телефон'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditPhoneDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Изменить дату лицензии'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditLicenceDateDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Подтверждение',
      content: 'Вы уверены, что хотите удалить эту компанию?',
    );

    if (confirmed) {
      if (!mounted) return;
      context.read<CompanyCubit>().deleteCompany(widget.company.id);
    }
  }

  void _showEditPhoneDialog() {
    final phoneWithoutLeading8 = widget.company.phone.startsWith('8')
        ? widget.company.phone.substring(1)
        : widget.company.phone;
    final phoneController = TextEditingController(text: phoneWithoutLeading8);
    final phoneFormatter = MaskTextInputFormatter(
      mask: ' (###) ###-##-##',
      filter: {"#": RegExp(r'\d')},
    );
    phoneController.value = phoneFormatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: phoneController.text),
    );
    String? phoneError;
    bool validatePhone(String value) {
      final rawPhone = value.replaceAll(RegExp(r'\D'), '');
      if (rawPhone.length != 10) {
        phoneError = 'Номер должен состоять из 10 цифр';
        return false;
      }
      phoneError = null;
      return true;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Color(AppColors.background),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Изменить телефон',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  LabeledTextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [phoneFormatter],
                    errorText: phoneError,
                    prefix: const Text('8 '),
                    label: 'Телефон администратора',
                    onChanged: (value) {
                      setState(() {
                        validatePhone(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Отмена',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.primary),
                        ),
                        onPressed: () {
                          if (!validatePhone(phoneController.text)) {
                            setState(() {});
                            return;
                          }
                          final newPhone =
                              '8${phoneFormatter.getUnmaskedText()}';
                          Navigator.of(context).pop();
                          context.read<CompanyCubit>().updatePhone(
                            widget.company.id,
                            newPhone,
                          );
                        },
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditLicenceDateDialog() {
    final dateController = TextEditingController(
      text:
          '${widget.company.licenceDate.day.toString().padLeft(2, '0')}.'
          '${widget.company.licenceDate.month.toString().padLeft(2, '0')}.'
          '${widget.company.licenceDate.year}',
    );

    String? dateError;
    DateTime? parsedDate;

    bool validateDate() {
      dateError = null;
      parsedDate = null;

      final text = dateController.text.trim();
      final regex = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');

      if (!regex.hasMatch(text)) {
        dateError = 'Введите дату в формате дд.мм.гггг';
        return false;
      }

      final match = regex.firstMatch(text)!;
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);

      try {
        final date = DateTime(year, month, day);
        if (date.day != day || date.month != month || date.year != year) {
          dateError = 'Некорректная дата';
          return false;
        }

        parsedDate = date;
        return true;
      } catch (_) {
        dateError = 'Некорректная дата';
        return false;
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Color(AppColors.background),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Изменить дату лицензии',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  LabeledTextField(
                    controller: dateController,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    errorText: dateError,
                    label: 'Дата лицензии',
                    onChanged: (value) {
                      setState(() {
                        validateDate();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Отмена',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.primary),
                        ),
                        onPressed: () {
                          if (!validateDate()) {
                            setState(() {});
                            return;
                          }
                          context.read<CompanyCubit>().updateLicenceDate(
                            widget.company.id,
                            parsedDate!,
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showOptionsMenu,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(
              widget.company.id.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.company.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.company.phone,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Text(
                  'Лицензия до:',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                Text(
                  _formatDate(widget.company.licenceDate),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
