import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/form_modal/info_row.dart';
import 'package:waypay/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay/features/clients/data/models/client_model.dart';
import 'package:waypay/features/clients/data/data_sources/clients_remote_data_source.dart';
import 'package:waypay/features/clients/data/models/update_client_doc_issue_date_requests.dart';
import 'package:waypay/features/clients/data/models/update_client_doc_request.dart';
import 'package:waypay/features/clients/data/models/update_client_request.dart';

class ClientCard extends StatefulWidget {
  final ClientModel client;
  final VoidCallback? onDeleted;
  const ClientCard({super.key, required this.client, this.onDeleted});

  @override
  State<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<ClientCard> {
  void _showEditClientModal(BuildContext context, ClientModel client) {
    final fullNameController = TextEditingController(text: client.fullName);
    String phoneWithoutLeading8 = client.phone;
    if (phoneWithoutLeading8.startsWith('8')) {
      phoneWithoutLeading8 = phoneWithoutLeading8.substring(1);
    }
    final phoneController = TextEditingController(text: phoneWithoutLeading8);
    final phoneFormatter = MaskTextInputFormatter(mask: ' (###) ###-##-##', filter: {"#": RegExp(r'\d')});

    phoneFormatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: phoneController.text));

    final addressController = TextEditingController(text: client.registrationAddress ?? '');
    final docController = TextEditingController(text: client.doc);

    String formatBirthdate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}';
    }

    final birthdateController = TextEditingController(text: formatBirthdate(client.birthdate));
    final docIssueYearController = TextEditingController(text: client.docIssueYear?.toString() ?? '');
    final dataSource = getIt<ClientRemoteDataSource>();

    String? birthdateError;
    String? docIssueYearError;
    String? phoneError;

    DateTime? parsedBirthdate;
    int? parsedDocIssueYear;

    bool validateInputs() {
      birthdateError = null;
      docIssueYearError = null;
      phoneError = null;
      parsedBirthdate = null;
      parsedDocIssueYear = null;

      bool isValid = true;

      final rawPhone = phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (rawPhone.length != 10) {
        phoneError = 'Номер должен состоять из 10 цифр';
        isValid = false;
      }

      final birthdateText = birthdateController.text.trim();
      final birthdateRegExp = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');
      if (!birthdateRegExp.hasMatch(birthdateText)) {
        birthdateError = 'Введите дату в формате дд.мм.гггг';
        isValid = false;
      } else {
        final match = birthdateRegExp.firstMatch(birthdateText)!;
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        try {
          final date = DateTime(year, month, day);
          if (date.day != day || date.month != month || date.year != year) {
            birthdateError = 'Некорректная дата';
            isValid = false;
          } else {
            final now = DateTime.now();
            final adultDate = DateTime(now.year - 18, now.month, now.day);
            if (date.isAfter(adultDate)) {
              birthdateError = 'Возраст должен быть не менее 18 лет';
              isValid = false;
            } else {
              parsedBirthdate = date;
            }
          }
        } catch (_) {
          birthdateError = 'Некорректная дата';
          isValid = false;
        }
      }

      final yearText = docIssueYearController.text.trim();
      if (yearText.isNotEmpty) {
        final yearInt = int.tryParse(yearText);
        final currentYear = DateTime.now().year;
        if (yearInt == null || yearInt < 1900 || yearInt > currentYear) {
          docIssueYearError = 'Введите корректный год (1900 - $currentYear)';
          isValid = false;
        } else {
          parsedDocIssueYear = yearInt;
        }
      }

      return isValid;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AppModal(
            title: 'Редактировать клиента',
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledTextField(
                    label: 'ФИО',
                    controller: fullNameController,
                    format: LabeledTextFieldFormat.fullName,
                    onChanged: (value) {
                      setState(() {
                        validateInputs();
                      });
                    },
                  ),
                  LabeledTextField(
                    label: 'Телефон',
                    controller: phoneController,
                    errorText: phoneError,
                    keyboardType: TextInputType.phone,
                    prefix: const Text('8 '),
                    inputFormatters: [phoneFormatter],
                    onChanged: (value) {
                      setState(() {
                        validateInputs();
                      });
                    },
                  ),
                  LabeledTextField(label: 'Адрес регистрации', controller: addressController, onChanged: (_) {}),
                  LabeledTextField(
                    label: 'Документ',
                    format: LabeledTextFieldFormat.passport,
                    controller: docController,
                    onChanged: (_) {},
                  ),
                  LabeledTextField(
                    label: 'Дата рождения (дд.мм.гггг)',
                    controller: birthdateController,
                    errorText: birthdateError,
                    keyboardType: TextInputType.datetime,

                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      setState(() {
                        validateInputs();
                      });
                    },
                  ),
                  LabeledTextField(
                    label: 'Год выдачи документа',
                    controller: docIssueYearController,
                    errorText: docIssueYearError,
                    keyboardType: TextInputType.number,

                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      setState(() {
                        validateInputs();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DefaultButton(
                    text: 'Сохранить',
                    color: const Color(AppColors.primary),
                    onPressed: () async {
                      if (!validateInputs()) {
                        setState(() {});
                        return;
                      }
                      final List<Future<void>> requests = [];
                      if (fullNameController.text != client.fullName ||
                          phoneController.text != client.phone ||
                          parsedBirthdate != client.birthdate ||
                          addressController.text != (client.registrationAddress ?? '')) {
                        final updateBasicRequest = UpdateClientRequest(
                          fullName: fullNameController.text,
                          phone: '8${phoneFormatter.getUnmaskedText()}',
                          birthdate: parsedBirthdate!.toUtc().toIso8601String(),
                          registrationAddress: addressController.text,
                        );
                        requests.add(dataSource.updateClientBasic(client.id, updateBasicRequest));
                      }
                      if (docController.text != client.doc) {
                        final updateDocRequest = UpdateClientDocRequest(doc: docController.text);
                        requests.add(dataSource.updateClientDoc(client.id, updateDocRequest));
                      }
                      if (parsedDocIssueYear != (client.docIssueYear ?? -1)) {
                        final dateForDocIssue = DateTime(parsedDocIssueYear!, 1, 1);
                        final updateDocIssueDateRequest = UpdateClientDocIssueDateRequest(
                          docIssueDate: dateForDocIssue.toUtc().toIso8601String(),
                        );
                        requests.add(dataSource.updateClientDocIssueDate(client.id, updateDocIssueDateRequest));
                      }
                      try {
                        if (requests.isNotEmpty) {
                          await Future.wait(requests);
                          if (!context.mounted) return;
                          if (widget.onDeleted != null) {
                            widget.onDeleted!();
                          }
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Данные обновлены')));
                        } else {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка обновления: $e')));
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showClientModal(BuildContext context, ClientModel client) {
    showDialog(
      context: context,
      builder: (_) => AppModal(
        title: 'Информация о клиенте',
        menuItems: [
          PopupMenuItem(
            child: const Text('Редактировать'),
            onTap: () {
              Future.delayed(Duration.zero, () {
                if (!context.mounted) return;
                Navigator.of(context).pop();
                _showEditClientModal(context, client);
              });
            },
          ),
          if (client.creditIds.isEmpty)
            PopupMenuItem(
              child: const Text('Удалить'),
              onTap: () async {
                Navigator.of(context).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Подтвердите удаление'),
                    content: const Text('Вы действительно хотите удалить клиента?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Удалить')),
                    ],
                  ),
                );

                if (confirmed == true) {
                  if (!context.mounted) return;
                  _deleteClient(context);
                }
              },
            ),
        ],

        content: SingleChildScrollView(
          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(label: 'ID', value: client.id.toString()),
              InfoRow(label: 'ФИО', value: client.fullName),
              InfoRow(label: 'Телефон', value: client.phone),
              InfoRow(label: 'Дата рождения', value: _formatDate(client.birthdate)),
              InfoRow(
                label: 'Номер договоров',
                value: (client.creditIds.isNotEmpty) ? client.creditIds.join(', ') : '-',
              ),
              InfoRow(
                label: 'Остатки месяцев',
                value: (client.creditRestTerms.isNotEmpty) ? client.creditRestTerms.join(', ') : '-',
              ),
              DefaultButton(text: 'Закрыть', color: Color(AppColors.primary), onPressed: () => context.pop()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteClient(BuildContext context) async {
    final dataSource = getIt<ClientRemoteDataSource>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await dataSource.deleteClient(widget.client.id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Клиент успешно удалён')));
      if (widget.onDeleted != null) {
        widget.onDeleted!();
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления клиента: $e')));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<void> _loadClientAndShowModal(BuildContext context) async {
    final dataSource = getIt<ClientRemoteDataSource>();
    try {
      final fullClient = await dataSource.getClientById(widget.client.id);
      if (!context.mounted) return;
      _showClientModal(context, fullClient);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки клиента: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _loadClientAndShowModal(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.client.creditIds.isNotEmpty ? Color(AppColors.pinkTint) : Color(AppColors.greenTint),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.client.fullName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(widget.client.phone, style: const TextStyle(fontSize: 14, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
