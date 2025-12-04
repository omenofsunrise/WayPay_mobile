import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay_mobile/core/widgets/app_modal.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/pagination_widget.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/features/finance/data/data_source/budget_remote_data_source.dart';
import 'package:waypay_mobile/features/finance/data/models/create_budget_income_dto.dart';
import 'package:waypay_mobile/features/finance/data/models/create_budget_outcome_dto.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_expense_bloc.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_income_bloc.dart';
import 'package:waypay_mobile/features/finance/presentation/widgets/budget_card.dart';
import 'package:waypay_mobile/features/finance/presentation/widgets/investor_selector_modal_content.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final userStorage = UserStorage();

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetIncomeBloc>().add(
        LoadBudgetIncomeEvent(month: selectedMonth, year: selectedYear),
      );
      context.read<BudgetExpenseBloc>().add(
        LoadBudgetExpenseEvent(month: selectedMonth, year: selectedYear),
      );
    });
  }

  String formatAmount(num amount) {
    return NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    ).format(amount);
  }

  void _loadData(bool isIncome, int month, int year) {
    if (isIncome) {
      context.read<BudgetIncomeBloc>().add(
        LoadBudgetIncomeEvent(month: month, year: year),
      );
    } else {
      context.read<BudgetExpenseBloc>().add(
        LoadBudgetExpenseEvent(month: month, year: year),
      );
    }
  }

  void _loadBothTabs() {
    _loadData(true, selectedMonth, selectedYear);
    _loadData(false, selectedMonth, selectedYear);
  }

  // === МОДАЛКА ФИЛЬТРОВ МЕСЯЦ/ГОД ===
  void _openFilterModal() {
    int tempMonth = selectedMonth;
    int tempYear = selectedYear;

    // берём блоки заранее (чтобы не зависеть от контекста диалога)
    final incomeBloc = context.read<BudgetIncomeBloc>();
    final expenseBloc = context.read<BudgetExpenseBloc>();

    showDialog(
      context: context,
      builder: (ctx) => AppModal(
        title: 'Фильтры',
        backgroundColor: const Color(AppColors.background),
        contentPadding: const EdgeInsets.all(16),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Период',
                  style: AppStyle.manrope16.copyWith(
                    color: const Color(AppColors.black),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: tempMonth,
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: List.generate(12, (i) => i + 1)
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                  toBeginningOfSentenceCase(
                                    DateFormat.MMMM(
                                      'ru_RU',
                                    ).format(DateTime(0, m)),
                                  )!,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setModalState(() => tempMonth = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: tempYear,
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_drop_down),
                        items:
                            List.generate(5, (i) => DateTime.now().year - 2 + i)
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(y.toString()),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setModalState(() => tempYear = v);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          DefaultButton(
            text: 'Сбросить',
            onPressed: () {
              final now = DateTime.now();
              tempMonth = now.month;
              tempYear = now.year;

              setState(() {
                selectedMonth = tempMonth;
                selectedYear = tempYear;
              });

              incomeBloc.add(
                LoadBudgetIncomeEvent(month: tempMonth, year: tempYear),
              );
              expenseBloc.add(
                LoadBudgetExpenseEvent(month: tempMonth, year: tempYear),
              );

              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          DefaultButton(
            text: 'Применить',
            isGreen: true,
            onPressed: () {
              setState(() {
                selectedMonth = tempMonth;
                selectedYear = tempYear;
              });

              incomeBloc.add(
                LoadBudgetIncomeEvent(month: tempMonth, year: tempYear),
              );
              expenseBloc.add(
                LoadBudgetExpenseEvent(month: tempMonth, year: tempYear),
              );

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddBudgetOutcomeModal() async {
    final amountController = TextEditingController();
    final commentController = TextEditingController();
    final amountError = ValueNotifier<String?>(null);

    await showDialog(
      context: context,
      builder: (dialogContext) => AppModal(
        backgroundColor: Color(AppColors.background),
        title: 'Добавить расход',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: amountError,
              builder: (_, error, __) => TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Сумма',
                  hintText: '0.0',
                  errorText: error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Комментарий (необязательно)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DefaultButton(
                    text: 'Отмена',
                    isGreen: false,
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultButton(
                    text: 'Сохранить',
                    isGreen: true,
                    onPressed: () async {
                      amountError.value = null;
                      final amountText = amountController.text.trim();

                      if (amountText.isEmpty ||
                          double.tryParse(amountText) == null ||
                          double.parse(amountText) <= 0) {
                        amountError.value = 'Введите корректную сумму';
                        return;
                      }

                      Navigator.pop(dialogContext);

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await getIt<BudgetRemoteDataSource>()
                            .createBudgetOutcome(
                              CreateBudgetOutcomeDto(
                                amount: double.parse(amountText),
                                comment: commentController.text.trim().isEmpty
                                    ? null
                                    : commentController.text.trim(),
                              ),
                            );

                        if (!context.mounted) return;
                        Navigator.pop(context);

                        context.read<BudgetExpenseBloc>().add(
                          LoadBudgetExpenseEvent(
                            month: selectedMonth,
                            year: selectedYear,
                          ),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Расход успешно добавлен'),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: Color(AppColors.background),
                            title: const Text('Ошибка'),
                            content: Text('Не удалось добавить расход.\n$e'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
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
      ),
    );
  }

  _showAddBudgetIncomeModal() {
    showDialog(
      context: context,
      builder: (_) => InvestorSelectorModalContent(
        onSave: (investor, amount, comment) async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          try {
            await getIt<BudgetRemoteDataSource>().createBudgetIncome(
              CreateBudgetIncomeDto(
                amount: amount,
                comment: comment,
                investorId: investor.id,
                companyShare: 100,
              ),
            );

            if (!mounted) return;
            Navigator.pop(context);
            context.read<BudgetIncomeBloc>().add(
              LoadBudgetIncomeEvent(month: selectedMonth, year: selectedYear),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Приход успешно добавлен')),
            );
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: Color(AppColors.background),
                title: const Text('Ошибка'),
                content: Text('Не удалось добавить приход.\n$e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ок'),
                  ),
                ],
              ),
            );
          }
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
        title: Text(
          'Бюджет',
          style: AppStyle.medium20.copyWith(
            color: const Color(AppColors.background),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: _openFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔻 Блок с выпадающими списками месяца/года удалён. Теперь только через модалку.
          BlocBuilder<BudgetIncomeBloc, BudgetIncomeState>(
            builder: (context, incomeState) {
              return BlocBuilder<BudgetExpenseBloc, BudgetExpenseState>(
                builder: (context, expenseState) {
                  final incomeTotal = incomeState is BudgetIncomeLoaded
                      ? incomeState.incomes.fold<double>(
                          0,
                          (sum, item) => sum + item.amount,
                        )
                      : 0.0;

                  final expenseTotal = expenseState is BudgetExpenseLoaded
                      ? expenseState.expenses.fold<double>(
                          0,
                          (sum, item) => sum + item.amount,
                        )
                      : 0.0;

                  return TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white,
                    indicatorColor: Colors.white,
                    tabs: [
                      Tab(text: 'Приходы: ${formatAmount(incomeTotal)}'),
                      Tab(text: 'Расходы: ${formatAmount(expenseTotal)}'),
                    ],
                  );
                },
              );
            },
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBudgetTab(
                  isIncome: true,
                  blocBuilder: BlocBuilder<BudgetIncomeBloc, BudgetIncomeState>(
                    builder: (context, state) {
                      if (state is BudgetIncomeLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is BudgetIncomeError) {
                        return Center(child: Text(state.message));
                      }
                      if (state is BudgetIncomeLoaded) {
                        return _buildBudgetContent(
                          totalCount: state.totalCount,
                          items: state.incomes
                              .map(
                                (i) => BudgetCard(
                                  amount: i.amount,
                                  comment: i.comment,
                                  createdAt: i.createdAt,
                                  isIncome: true,
                                  id: i.id,
                                ),
                              )
                              .toList(),
                          currentPage: state.currentPage,
                          totalPages: state.totalPages,
                          onPageSelected: (page) {
                            context.read<BudgetIncomeBloc>().add(
                              LoadBudgetIncomeEvent(
                                page: page,
                                month: selectedMonth,
                                year: selectedYear,
                              ),
                            );
                          },
                          onAddPressed: _showAddBudgetIncomeModal,
                          onRefresh: () async {
                            context.read<BudgetIncomeBloc>().add(
                              LoadBudgetIncomeEvent(
                                page: state.currentPage,
                                month: selectedMonth,
                                year: selectedYear,
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                _buildBudgetTab(
                  isIncome: false,
                  blocBuilder:
                      BlocBuilder<BudgetExpenseBloc, BudgetExpenseState>(
                        builder: (context, state) {
                          if (state is BudgetExpenseLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state is BudgetExpenseError) {
                            return Center(child: Text(state.message));
                          }
                          if (state is BudgetExpenseLoaded) {
                            return _buildBudgetContent(
                              totalCount: state.totalCount,
                              items: state.expenses
                                  .map(
                                    (e) => BudgetCard(
                                      amount: e.amount,
                                      comment: e.comment,
                                      createdAt: e.createdAt,
                                      isIncome: false,
                                      id: e.id,
                                    ),
                                  )
                                  .toList(),
                              currentPage: state.currentPage,
                              totalPages: state.totalPages,
                              onPageSelected: (page) {
                                context.read<BudgetExpenseBloc>().add(
                                  LoadBudgetExpenseEvent(
                                    page: page,
                                    month: selectedMonth,
                                    year: selectedYear,
                                  ),
                                );
                              },
                              onAddPressed: _showAddBudgetOutcomeModal,
                              onRefresh: () async {
                                context.read<BudgetExpenseBloc>().add(
                                  LoadBudgetExpenseEvent(
                                    page: state.currentPage,
                                    month: selectedMonth,
                                    year: selectedYear,
                                  ),
                                );
                              },
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTab({
    required bool isIncome,
    required Widget blocBuilder,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: blocBuilder,
    );
  }

  Widget _buildBudgetContent({
    required int totalCount,
    required List<Widget> items,
    required int currentPage,
    required int totalPages,
    required VoidCallback onAddPressed,
    required ValueChanged<int> onPageSelected,
    required Future<void> Function() onRefresh,
  }) {
    final hasData = items.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: Refresher(
            onRefresh: onRefresh,
            content: hasData
                ? ListView(padding: const EdgeInsets.all(16), children: items)
                : const Center(
                    child: Text(
                      'Нет данных',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
          ),
        ),
        // Кнопку "Добавить" оставил как в исходнике (закомментирована). Включите при необходимости.
        if (hasData)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: PaginationWidget(
              currentPage: currentPage,
              totalPages: totalPages,
              onPageSelected: onPageSelected,
            ),
          ),
      ],
    );
  }
}
