import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/models/employee_role.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/core/widgets/refresh.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay/features/investors/presentation/widgets/investos_card.dart';
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
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.userTypeSelectionScreen.toName);
    }
  }

  void _showAddInvestorModal() {
    final nicknameController = TextEditingController();
    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();
    final pieController = TextEditingController();
    final investmentController = TextEditingController();

    final phoneFormatter = MaskTextInputFormatter(
      mask: '8 (###) ###-##-##',
      filter: {"#": RegExp(r'\d')},
    );

    String? nicknameError;
    String? fullNameError;
    String? phoneError;
    String? pieError;
    String? investmentError;

    bool validateInputs() {
      bool isValid = true;

      nicknameError = null;
      fullNameError = null;
      phoneError = null;
      pieError = null;
      investmentError = null;

      if (nicknameController.text.trim().isEmpty) {
        nicknameError = 'Введите никнейм';
        isValid = false;
      }
      if (fullNameController.text.trim().isEmpty) {
        fullNameError = 'Введите ФИО';
        isValid = false;
      }
      final phone = phoneFormatter.getUnmaskedText();
      if (phone.length != 10) {
        phoneError = 'Номер должен состоять из 10 цифр';
        isValid = false;
      }
      if (pieController.text.trim().isEmpty) {
        pieError = 'Введите долю';
        isValid = false;
      } else {
        final pieValue = int.tryParse(pieController.text.trim());
        if (pieValue == null || pieValue < 0 || pieValue > 100) {
          pieError = 'Введите число от 0 до 100';
          isValid = false;
        }
      }
      if (investmentController.text.trim().isEmpty) {
        investmentError = 'Введите сумму';
        isValid = false;
      } else {
        final investmentValue = double.tryParse(
          investmentController.text.trim(),
        );
        if (investmentValue == null || investmentValue < 0) {
          investmentError = 'Введите корректное число';
          isValid = false;
        }
      }

      return isValid;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AppModal(
            title: 'Добавить инвестора',
            content: Column(
              children: [
                LabeledTextField(
                  label: 'Никнейм',
                  controller: nicknameController,
                  errorText: nicknameError,
                ),
                LabeledTextField(
                  label: 'ФИО',
                  controller: fullNameController,
                  errorText: fullNameError,
                  format: LabeledTextFieldFormat.fullName,
                ),
                _buildPhoneField(
                  controller: phoneController,
                  formatter: phoneFormatter,
                  errorText: phoneError,
                ),
                LabeledTextField(
                  label: 'Доля инвестора (%)',
                  controller: pieController,
                  keyboardType: TextInputType.number,
                  errorText: pieError,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                LabeledTextField(
                  label: 'Инвестиция',
                  controller: investmentController,
                  keyboardType: TextInputType.number,
                  errorText: investmentError,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DefaultButton(
                        text: 'Отмена',
                        color: const Color(AppColors.greyLight),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DefaultButton(
                        text: 'Создать',
                        color: const Color(AppColors.primary),
                        onPressed: () async {
                          if (!validateInputs()) {
                            setState(() {});
                            return;
                          }

                          Navigator.pop(dialogContext);

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          try {
                            await getIt<InvestorsRemoteDataSource>()
                                .createInvestor(
                                  nickname: nicknameController.text.trim(),
                                  fullName: fullNameController.text.trim(),
                                  phoneNumber:
                                      phoneController.text.trim().isEmpty
                                      ? null
                                      : phoneController.text.trim(),
                                  investorPie:
                                      int.tryParse(pieController.text) ?? 0,
                                  investmentAmount:
                                      double.tryParse(
                                        investmentController.text,
                                      ) ??
                                      0.0,
                                );

                            if (mounted) {
                              Navigator.pop(context);
                            }

                            context.read<InvestorsBloc>().add(
                              LoadInvestorsEvent(refresh: true, page: 1),
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Инвестор успешно создан'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                            }
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Ошибка'),
                                  content: Text(
                                    'Не удалось создать инвестора.\n$e',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),

                                      child: const Text('Ок'),
                                    ),
                                  ],
                                ),
                              );
                            }
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
      drawer: AppDrawer(),
      backgroundColor: const Color(AppColors.primaryLight),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(AppColors.primaryLight),
        elevation: 0,
        title: Text(
          'Инвесторы',
          style: AppStyle.medium20.copyWith(color: Color(AppColors.background)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'Профиль',
            onPressed: () {
              context.pushNamed(Routes.profileScreen.toName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Выйти',
            onPressed: _logout,
          ),
        ],
      ),
      body: ValueListenableBuilder<EmployeeRole?>(
        valueListenable: UserStorage().roleNotifier,
        builder: (context, role, _) {
          final canAddInvestor = UserStorage().canViewAdminContent();
          return Column(
            children: [
              Container(
                color: const Color(AppColors.primaryLight),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    BlocBuilder<InvestorsBloc, InvestorsState>(
                      builder: (context, state) {
                        double totalAmount = 0;
                        if (state is InvestorsLoaded) {
                          totalAmount = state.investors.fold(
                            0,
                            (sum, investor) => sum + investor.balance,
                          );
                        }
                        return Text(
                          'Всего: ${totalAmount.toStringAsFixed(0)} ₽',
                          style: AppStyle.inter(
                            size: 24,
                            weight: FontWeight.w300,
                            color: Color(AppColors.background),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Поиск счетов...',
                        hintStyle: const TextStyle(color: Colors.white),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 500),
                          () {
                            final bloc = context.read<InvestorsBloc>();
                            if (value.isNotEmpty) {
                              bloc.add(SearchInvestorsEvent(value));
                            } else {
                              bloc.add(ResetSearchInvestorsEvent());
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
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
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Color(AppColors.red),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Ошибка загрузки',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(AppColors.red),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (state.message.contains('Сессия истекла') ||
                                    state.message.contains('авторизации')) ...[
                                  ElevatedButton(
                                    onPressed: _logout,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(AppColors.red),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Войти заново'),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                ElevatedButton(
                                  onPressed: () => context
                                      .read<InvestorsBloc>()
                                      .add(LoadInvestorsEvent(refresh: true)),
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
                                  final bloc = context.read<InvestorsBloc>();
                                  final state = bloc.state;
                                  int currentPage = 1;
                                  if (state is InvestorsLoaded) {
                                    currentPage = state.currentPage;
                                  }
                                  bloc.add(
                                    LoadInvestorsEvent(
                                      refresh: true,
                                      page: currentPage,
                                    ),
                                  );
                                },
                                content: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.investors.length,
                                  itemBuilder: (context, index) {
                                    return InvestorCard(
                                      investor: state.investors[index],
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (canAddInvestor)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: DefaultButton(
                                  text: 'Добавить инвестора',
                                  color: Color(AppColors.primaryLight),
                                  onPressed: _showAddInvestorModal,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 16,
                              ),
                              child: PaginationWidget(
                                currentPage: state.currentPage,
                                totalPages: state.totalPages,
                                onPageSelected: (page) {
                                  context.read<InvestorsBloc>().add(
                                    LoadInvestorsEvent(
                                      refresh: true,
                                      page: page,
                                    ),
                                  );
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
            style: AppStyle.medium16.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [formatter],
            decoration: InputDecoration(
              hintText: 'Телефон',
              errorText: errorText,
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
    );
  }
}
