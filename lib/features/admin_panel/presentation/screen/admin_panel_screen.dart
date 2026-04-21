import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/features/admin_panel/data/models/post_company_model.dart';
import 'package:waypay_mobile/features/admin_panel/presentation/cubit/company_cubit.dart';
import 'package:waypay_mobile/routes/routes.dart';
import 'package:waypay_styles/waypay_styles.dart';

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

    final phoneFormatter = MaskTextInputFormatter(
      mask: ' (###) ###-##-##',
      filter: {"#": RegExp(r'\d')},
    );

    DateTime? parsedDate;

    bool validatePhone(String value) {
      final raw = value.replaceAll(RegExp(r'\D'), '');
      if (raw.length != 10) {
        return false;
      }
      return true;
    }

    bool validateDate() {
      parsedDate = null;
      final text = dateController.text.trim();
      final regex = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');

      if (!regex.hasMatch(text)) {
        return false;
      }

      final match = regex.firstMatch(text)!;
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);

      try {
        final date = DateTime(year, month, day);
        if (date.day != day || date.month != month || date.year != year) {
          return false;
        }
        parsedDate = date;
        return true;
      } catch (_) {
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
                    'Добавить компанию',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 20),
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
                        onPressed: () async {
                          final isPhoneValid = validatePhone(
                            phoneController.text,
                          );
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

                          await context.read<CompanyCubit>().createCompany(
                            request,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Создать',
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
    return Scaffold(
      backgroundColor: Color(AppColors.primary),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: Container(
            color: const Color(AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Header(
              title: 'Управление',
              showBackButton: true,
              showNotifications: false,
              showAvatar: false,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(AppColors.background),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
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
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
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
                                      return const SizedBox.shrink();
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
                            isPrimary: true,
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
