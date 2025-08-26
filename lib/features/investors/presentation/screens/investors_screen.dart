import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/core/widgets/refresh.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay/features/investors/presentation/widgets/investor_card.dart';
import 'package:waypay/features/profile/data/models/employee.dart';
import 'package:waypay/routes/routes.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/widgets/default_button.dart';
import '../bloc/investors_bloc.dart';

class InvestorsScreen extends StatefulWidget {
  const InvestorsScreen({super.key});

  @override
  State<InvestorsScreen> createState() => _InvestorsScreenState();
}

class _InvestorsScreenState extends State<InvestorsScreen> {
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InvestorsBloc>().add(LoadInvestorsEvent());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (!mounted) return;
    context.pushReplacementNamed(Routes.phoneAuthScreen.toName);
  }

  void _openFilterModal() {
    final investorsBloc = context.read<InvestorsBloc>();
    final tempController = TextEditingController(text: _searchController.text);

    showDialog(
      context: context,
      builder: (_) => AppModal(
        title: 'Фильтры',
        backgroundColor: const Color(AppColors.background),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: tempController,
              decoration: InputDecoration(
                hintText: 'Поиск инвесторов...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  final q = value.trim();
                  if (q.isNotEmpty) {
                    investorsBloc.add(SearchInvestorsEvent(q));
                  } else {
                    investorsBloc.add(ResetSearchInvestorsEvent());
                  }
                });
              },
            ),
          ],
        ),
        actions: [
          DefaultButton(
            text: 'Сбросить',
            onPressed: () {
              tempController.clear();
              setState(() => _searchController.clear());
              investorsBloc.add(ResetSearchInvestorsEvent());
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          DefaultButton(
            text: 'Применить',
            isGreen: true,
            onPressed: () {
              setState(() => _searchController.text = tempController.text);
              final q = _searchController.text.trim();
              if (q.isNotEmpty) {
                investorsBloc.add(SearchInvestorsEvent(q));
              } else {
                investorsBloc.add(ResetSearchInvestorsEvent());
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddInvestorModal() {
    final nicknameController = TextEditingController();
    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();
    final pieController = TextEditingController();
    final investmentController = TextEditingController();

    final phoneFormatter = MaskTextInputFormatter(mask: '8 (###) ###-##-##', filter: {"#": RegExp(r'\d')});

    final ValueNotifier<String?> nicknameError = ValueNotifier(null);
    final ValueNotifier<String?> fullNameError = ValueNotifier(null);
    final ValueNotifier<String?> phoneError = ValueNotifier(null);
    final ValueNotifier<String?> pieError = ValueNotifier(null);
    final ValueNotifier<String?> investmentError = ValueNotifier(null);

    bool validateInputs() {
      bool isValid = true;

      nicknameError.value = null;
      fullNameError.value = null;
      phoneError.value = null;
      pieError.value = null;
      investmentError.value = null;

      if (nicknameController.text.trim().isEmpty) {
        nicknameError.value = 'Введите никнейм';
        isValid = false;
      }
      if (fullNameController.text.trim().isEmpty) {
        fullNameError.value = 'Введите ФИО';
        isValid = false;
      }
      final phone = phoneFormatter.getUnmaskedText();
      if (phone.length != 10) {
        phoneError.value = 'Номер должен состоять из 10 цифр';
        isValid = false;
      }
      if (pieController.text.trim().isEmpty) {
        pieError.value = 'Введите долю';
        isValid = false;
      } else {
        final pieValue = int.tryParse(pieController.text.trim());
        if (pieValue == null || pieValue < 0 || pieValue > 100) {
          pieError.value = 'Введите число от 0 до 100';
          isValid = false;
        }
      }
      if (investmentController.text.trim().isEmpty) {
        investmentError.value = 'Введите сумму';
        isValid = false;
      } else {
        final investmentValue = double.tryParse(investmentController.text.trim());
        if (investmentValue == null || investmentValue < 0) {
          investmentError.value = 'Введите корректное число';
          isValid = false;
        }
      }

      return isValid;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerDialogContext, setState) {
          return AppModal(
            backgroundColor: Color(AppColors.background),
            title: 'Добавить инвестора',
            content: Column(
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: nicknameError,
                  builder: (_, error, __) =>
                      LabeledTextField(label: 'Никнейм', controller: nicknameController, errorText: error),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: fullNameError,
                  builder: (_, error, __) => LabeledTextField(
                    label: 'ФИО',
                    controller: fullNameController,
                    errorText: error,
                    format: LabeledTextFieldFormat.fullName,
                  ),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: phoneError,
                  builder: (_, error, __) =>
                      _buildPhoneField(controller: phoneController, formatter: phoneFormatter, errorText: error),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: pieError,
                  builder: (_, error, __) => LabeledTextField(
                    label: 'Доля инвестора (%)',
                    controller: pieController,
                    keyboardType: TextInputType.number,
                    errorText: error,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: investmentError,
                  builder: (_, error, __) => LabeledTextField(
                    label: 'Инвестиция',
                    controller: investmentController,
                    keyboardType: TextInputType.number,
                    errorText: error,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DefaultButton(
                        text: 'Отмена',
                        isGreen: false,
                        onPressed: () {
                          if (!innerDialogContext.mounted) return;
                          Navigator.pop(innerDialogContext);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DefaultButton(
                        text: 'Создать',
                        isGreen: true,
                        onPressed: () async {
                          if (!validateInputs()) {
                            setState(() {});
                            return;
                          }

                          if (!innerDialogContext.mounted) return;
                          Navigator.pop(innerDialogContext);

                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );

                          try {
                            await getIt<InvestorsRemoteDataSource>().createInvestor(
                              nickname: nicknameController.text.trim(),
                              fullName: fullNameController.text.trim(),
                              phoneNumber: phoneController.text.trim().isEmpty
                                  ? null
                                  : phoneFormatter.getUnmaskedText(),
                              investorPie: int.tryParse(pieController.text.trim()) ?? 0,
                              investmentAmount: double.tryParse(investmentController.text.trim()) ?? 0.0,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            if (!context.mounted) return;
                            context.read<InvestorsBloc>().add(LoadInvestorsEvent(refresh: true, page: 1));

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('Инвестор успешно создан')));
                          } catch (e) {
                            if (!context.mounted) return;
                            Navigator.pop(context);

                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Ошибка'),
                                content: Text('Не удалось создать инвестора.\n$e'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Ок'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(AppColors.primary),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(AppColors.primary),
        elevation: 0,
        title: Text('Инвесторы', style: AppStyle.medium20.copyWith(color: const Color(AppColors.background))),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: _openFilterModal,
          ),
        ],
      ),
      body: ValueListenableBuilder<EmployeeRole?>(
        valueListenable: UserStorage().roleNotifier,
        builder: (context, role, _) {
          return Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: BlocBuilder<InvestorsBloc, InvestorsState>(
                    builder: (context, state) {
                      if (state is InvestorsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is InvestorsError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 64, color: Color(AppColors.red)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Ошибка загрузки',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(AppColors.red)),
                                ),
                                const SizedBox(height: 16),
                                if (state.message.contains('Сессия истекла') ||
                                    state.message.contains('авторизации')) ...[
                                  ElevatedButton(
                                    onPressed: _logout,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(AppColors.red),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Войти заново'),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                ElevatedButton(
                                  onPressed: () {
                                    if (!context.mounted) return;
                                    context.read<InvestorsBloc>().add(LoadInvestorsEvent(refresh: true));
                                  },
                                  child: const Text('Повторить'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state is InvestorsLoaded) {
                        if (state.investors.isEmpty) {
                          return const Center(child: Text('Счета не найдены'));
                        }
                        return Column(
                          children: [
                            Expanded(
                              child: Refresher(
                                onRefresh: () async {
                                  if (!context.mounted) return;
                                  final bloc = context.read<InvestorsBloc>();
                                  final currentState = bloc.state;
                                  int currentPage = 1;
                                  if (currentState is InvestorsLoaded) {
                                    currentPage = currentState.currentPage;
                                  }
                                  bloc.add(LoadInvestorsEvent(refresh: true, page: currentPage));
                                },
                                content: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.investors.length,
                                  itemBuilder: (context, index) {
                                    return InvestorCard(investor: state.investors[index]);
                                  },
                                ),
                              ),
                            ),
                            // Если нужна кнопка добавления — раскомментируйте блок ниже
                            // Padding(
                            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            //   child: DefaultButton(
                            //     text: 'Добавить инвестора',
                            //     isGreen: true,
                            //     onPressed: _showAddInvestorModal,
                            //   ),
                            // ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 16),
                              child: PaginationWidget(
                                currentPage: state.currentPage,
                                totalPages: state.totalPages,
                                onPageSelected: (page) {
                                  if (!context.mounted) return;
                                  context.read<InvestorsBloc>().add(LoadInvestorsEvent(refresh: true, page: page));
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required MaskTextInputFormatter formatter,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Телефон',
            style: AppStyle.medium16.copyWith(color: Colors.black87, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [formatter],
            decoration: InputDecoration(
              hintText: 'Телефон',
              errorText: errorText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(AppColors.primary)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(AppColors.primary), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
