import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/form_modal/labeled_container.dart';
import 'package:waypay/core/widgets/helpers.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay/features/clients/data/models/clients/client_model.dart';
import 'package:waypay/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay/features/clients/data/models/clients/update_client_doc_issue_date_requests.dart';
import 'package:waypay/features/clients/data/models/clients/update_client_doc_request.dart';
import 'package:waypay/features/clients/data/models/clients/update_client_request.dart';

class ClientCard extends StatefulWidget {
  final ClientModel client;
  final VoidCallback? onDeleted;

  const ClientCard({super.key, required this.client, this.onDeleted});

  @override
  State<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<ClientCard> {
  String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'ru_RU').format(date);
  }

  Future<void> loadClientAndShowModal() async {
    final dataSource = getIt<ClientRemoteDataSource>();
    try {
      final fullClient = await dataSource.getClientById(widget.client.id);
      if (!context.mounted) return;
      showClientModal(fullClient);
    } catch (e) {
      if (!mounted) return;
      showMessage('Ошибка загрузки клиента: $e', context);
    }
  }

  void showClientModal(ClientModel client) {
    showDialog(
      context: context,
      builder: (_) => AppModal(
        backgroundColor: Color(AppColors.background),
        title: 'О клиенте',
        menuItems: [
          PopupMenuItem(
            child: const Text('Редактировать'),
            onTap: () {
              Future.delayed(Duration.zero, () {
                if (!mounted) return;
                Navigator.of(context).pop();
                showEditClientModal(client);
              });
            },
          ),
          if (client.creditIds.isEmpty)
            PopupMenuItem(
              child: const Text('Удалить'),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  confirmAndDeleteClient();
                });
              },
            ),
        ],
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledContainer(label: 'ID', text: client.id.toString()),
              LabeledContainer(label: 'ФИО', text: client.fullName),
              LabeledContainer(label: 'Телефон', text: client.phone),
              LabeledContainer(label: 'Дата рождения', text: _formatDate(client.birthdate)),
              LabeledContainer(
                label: 'Номер договоров',
                text: (client.creditIds.isNotEmpty) ? client.creditIds.join(', ') : '-',
              ),
              LabeledContainer(
                label: 'Остатки месяцев',
                text: (client.creditRestTerms.isNotEmpty) ? client.creditRestTerms.join(', ') : '-',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showEditClientModal(ClientModel client) {
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

    final docIssueDateController = TextEditingController(
      text: client.docIssueYear != null ? '01.01.${client.docIssueYear}' : '',
    );

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
          final now = DateTime.now();
          final adultDate = DateTime(now.year - 18, now.month, now.day);
          if (date.isAfter(adultDate)) {
            birthdateError = 'Возраст должен быть не менее 18 лет';
            isValid = false;
          } else {
            parsedBirthdate = date;
          }
        } catch (_) {
          birthdateError = 'Некорректная дата';
          isValid = false;
        }
      }
      final docIssueText = docIssueDateController.text.trim();
      if (docIssueText.isNotEmpty) {
        final docDateRegExp = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');
        if (!docDateRegExp.hasMatch(docIssueText)) {
          docIssueYearError = 'Введите дату в формате дд.мм.гггг';
          isValid = false;
        } else {
          final match = docDateRegExp.firstMatch(docIssueText)!;
          final year = int.parse(match.group(3)!);
          final minYear = DateTime.now().year - 100;
          final maxYear = DateTime.now().year;

          if (year < minYear || year > maxYear) {
            docIssueYearError = 'Некорректная дата';
            isValid = false;
          } else {
            parsedDocIssueYear = year;
          }
        }
      }

      return isValid;
    }

    Future<void> onSavePressed(BuildContext dialogContext, void Function(void Function()) setState) async {
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

      if (parsedDocIssueYear != null && parsedDocIssueYear != (client.docIssueYear ?? -1)) {
        final dateForDocIssue = DateTime(parsedDocIssueYear!, 1, 1);
        final updateDocIssueDateRequest = UpdateClientDocIssueDateRequest(
          docIssueDate: dateForDocIssue.toUtc().toIso8601String(),
        );
        requests.add(dataSource.updateClientDocIssueDate(client.id, updateDocIssueDateRequest));
      }

      try {
        if (requests.isNotEmpty) {
          await Future.wait(requests);
          if (!mounted) return;

          if (widget.onDeleted != null) {
            widget.onDeleted!();
          }
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext).pop();
          showMessage('Данные обновлены', context);
        } else {
          Navigator.of(dialogContext).pop();
        }
      } catch (e) {
        showMessage('Ошибка обновления: $e', context);
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AppModal(
            backgroundColor: Color(AppColors.background),
            title: 'Редактировать клиента',
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledTextField(
                    label: 'ФИО',
                    controller: fullNameController,
                    format: LabeledTextFieldFormat.fullName,
                    onChanged: (_) => setState(() => validateInputs()),
                  ),
                  LabeledTextField(
                    label: 'Телефон',
                    controller: phoneController,
                    errorText: phoneError,
                    keyboardType: TextInputType.phone,
                    prefix: const Text('8 '),
                    inputFormatters: [phoneFormatter],
                    onChanged: (_) => setState(() => validateInputs()),
                  ),
                  LabeledTextField(label: 'Адрес регистрации', controller: addressController),
                  LabeledTextField(
                    label: 'Документ',
                    format: LabeledTextFieldFormat.passport,
                    controller: docController,
                  ),
                  LabeledTextField(
                    label: 'Дата рождения (дд.мм.гггг)',
                    controller: birthdateController,
                    errorText: birthdateError,
                    keyboardType: TextInputType.datetime,
                    format: LabeledTextFieldFormat.birthdate,
                    onChanged: (_) => setState(() => validateInputs()),
                  ),
                  LabeledTextField(
                    label: 'Дата выдачи документа (дд.мм.гггг)',
                    controller: docIssueDateController,
                    errorText: docIssueYearError,
                    keyboardType: TextInputType.datetime,
                    format: LabeledTextFieldFormat.birthdate,
                    onChanged: (_) => setState(() => validateInputs()),
                  ),
                  const SizedBox(height: 12),
                  DefaultButton(text: 'Сохранить', isGreen: true, onPressed: () => onSavePressed(context, setState)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> confirmAndDeleteClient() async {
    final confirmed = await showConfirmDialog(context: context);
    if (confirmed) {
      await deleteClient();
    }
  }

  Future<void> deleteClient() async {
    final dataSource = getIt<ClientRemoteDataSource>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await dataSource.deleteClient(widget.client.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage('Клиент успешно удалён', context);
      if (widget.onDeleted != null) {
        widget.onDeleted!();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showMessage('Ошибка удаления клиента: $e', context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loadClientAndShowModal,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.client.creditIds.isNotEmpty
              ? const Color(AppColors.pinkTint)
              : const Color(AppColors.greenTint),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.client.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(widget.client.phone, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('Дата рождения: ${_formatDate(widget.client.birthdate)}', style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
