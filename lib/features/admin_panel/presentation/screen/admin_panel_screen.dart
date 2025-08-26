import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay/core/widgets/refresh.dart';
import 'package:waypay/features/admin_panel/data/models/post_company_model.dart';
import 'package:waypay/features/admin_panel/presentation/cubit/company_cubit.dart';
import 'package:waypay/features/admin_panel/presentation/widgets/company_card.dart';
import 'package:waypay/routes/routes.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _tokenStorage = TokenStorage();

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.phoneAuthScreen.toName);
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<CompanyCubit>().loadCompanies();
  }

  void showCreateCompanyDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final dateController = TextEditingController();
    final nameDirController = TextEditingController();
    final nameCompanyController = TextEditingController();

    final phoneFormatter = MaskTextInputFormatter(mask: ' (###) ###-##-##', filter: {"#": RegExp(r'\d')});

    String? phoneError;
    String? dateError;
    DateTime? parsedDate;

    bool validatePhone(String value) {
      final raw = value.replaceAll(RegExp(r'\D'), '');
      if (raw.length != 10) {
        phoneError = 'Номер должен состоять из 10 цифр';
        return false;
      }
      phoneError = null;
      return true;
    }

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Добавить компанию', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  LabeledTextField(
                    controller: nameDirController,
                    label: 'ФИО директора',
                    format: LabeledTextFieldFormat.fullName,
                  ),
                  LabeledTextField(controller: nameCompanyController, label: 'Название компании'),
                  LabeledTextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [phoneFormatter],
                    errorText: phoneError,
                    prefix: const Text('8 '),
                    label: 'Телефон администратора',
                    onChanged: (value) => setState(() => validatePhone(value)),
                  ),
                  LabeledTextField(
                    controller: dateController,
                    keyboardType: TextInputType.datetime,
                    format: LabeledTextFieldFormat.birthdate,
                    errorText: dateError,
                    label: 'Дата лицензии (дд.мм.гггг)',
                    onChanged: (value) => setState(() => validateDate()),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Отмена', style: TextStyle(color: Colors.black)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(AppColors.primary)),
                        onPressed: () async {
                          final isPhoneValid = validatePhone(phoneController.text);
                          final isDateValid = validateDate();

                          if (!isPhoneValid || !isDateValid) {
                            setState(() {});
                            return;
                          }

                          final phone = '8${phoneFormatter.getUnmaskedText()}';
                          final licence = parsedDate!;
                          final request = CompanyCreateRequest(
                            adminPhone: phone,
                            licenceDate: licence.toUtc().toIso8601String(),
                            adminName: nameDirController.text,
                            companyName: nameCompanyController.text,
                          );

                          await context.read<CompanyCubit>().createCompany(request);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                        child: const Text('Создать', style: TextStyle(color: Colors.white)),
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
    return Scaffold(
      drawer: AppDrawer(),
      backgroundColor: Color(AppColors.primary),
      appBar: AppBar(
        backgroundColor: Color(AppColors.primary),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Управление', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(AppColors.background),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: BlocBuilder<CompanyCubit, CompanyState>(
                builder: (context, state) {
                  if (state is CompanyLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CompanyError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (state.message.contains('Сессия')) {
                                  _logout();
                                } else {
                                  context.read<CompanyCubit>().loadCompanies();
                                }
                              },
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is CompanyLoaded) {
                    return Column(
                      children: [
                        Expanded(
                          child: state.companies.isEmpty
                              ? const Center(child: Text('Чёрный список пуст'))
                              : Refresher(
                                  onRefresh: () async {
                                    final cubit = context.read<CompanyCubit>();
                                    cubit.loadCompanies();
                                  },
                                  content: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: state.companies.length,
                                    itemBuilder: (context, index) {
                                      return CompanyCard(company: state.companies[index]);
                                    },
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DefaultButton(
                            text: 'Добавить компанию',
                            onPressed: () => showCreateCompanyDialog(context),
                            isGreen: true,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
