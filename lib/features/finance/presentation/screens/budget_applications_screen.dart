import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_expense_bloc.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_income_bloc.dart';
import 'package:waypay_mobile/features/finance/presentation/screens/add_budget_income_screen.dart';
import 'package:waypay_mobile/features/finance/presentation/screens/add_budget_expense_screen.dart';

class BudgetApplicationsScreen extends StatefulWidget {
  const BudgetApplicationsScreen({super.key});

  @override
  State<BudgetApplicationsScreen> createState() =>
      _BudgetApplicationsScreenState();
}

class _BudgetApplicationsScreenState extends State<BudgetApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  bool get _isIncomeTab => _tabController.index == 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted && !_tabController.indexIsChanging) {
          setState(() {});
        }
      });
    _updateDateControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadAll();
    });
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reloadAll() async {
    await Future.wait([_loadIncome(page: 1), _loadExpense(page: 1)]);
  }

  Future<void> _loadIncome({int? page}) async {
    // ignore: avoid_print
    print(
      '[BudgetScreen][LOAD_INCOME] month=$_selectedMonth year=$_selectedYear page=$page',
    );
    context.read<BudgetIncomeBloc>().add(
      LoadBudgetIncomeEvent(
        month: _selectedMonth,
        year: _selectedYear,
        page: page,
      ),
    );
  }

  Future<void> _loadExpense({int? page}) async {
    context.read<BudgetExpenseBloc>().add(
      LoadBudgetExpenseEvent(
        month: _selectedMonth,
        year: _selectedYear,
        page: page,
      ),
    );
  }

  void _updateDateControllers() {
    _monthController.text = _monthName(_selectedMonth);
    _yearController.text = _selectedYear.toString();
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'ru_RU',
      decimalDigits: 0,
      symbol: '₽',
    ).format(amount);
  }

  String _monthName(int month) {
    final formatter = DateFormat.MMMM('ru_RU');
    final value = formatter.format(DateTime(0, month));
    return value[0].toUpperCase() + value.substring(1);
  }

  void _onAddPressed() {
    if (_isIncomeTab) {
      _openAddIncomeScreen();
    } else {
      _openAddExpenseScreen();
    }
  }

  Future<void> _openAddIncomeScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddBudgetIncomeScreen()),
    );
    if (result == true) {
      await _loadIncome();
    }
  }

  Future<void> _openAddExpenseScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddBudgetExpenseScreen()),
    );
    if (result == true) {
      await _loadExpense();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Header(
                    title: 'Бюджет',
                    showBackButton: true,
                    showNotifications: false,
                    trailing: AddButton(onPressed: _onAddPressed),
                  ),
                  const SizedBox(height: 16),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  _buildFilters(),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildIncomeTab(), _buildExpenseTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return BlocBuilder<BudgetIncomeBloc, BudgetIncomeState>(
      builder: (context, incomeState) {
        final incomeAmount = incomeState is BudgetIncomeLoaded
            ? incomeState.incomes.fold<double>(
                0,
                (sum, item) => sum + item.amount,
              )
            : 0.0;

        return BlocBuilder<BudgetExpenseBloc, BudgetExpenseState>(
          builder: (context, expenseState) {
            final expenseAmount = expenseState is BudgetExpenseLoaded
                ? expenseState.expenses.fold<double>(
                    0,
                    (sum, item) => sum + item.amount,
                  )
                : 0.0;

            return CustomTabSwitcher(
              controller: _tabController,
              tabs: [
                'Приходы ${_formatCurrency(incomeAmount)}',
                'Расходы ${_formatCurrency(expenseAmount)}',
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: _buildPickerField(
            controller: _monthController,
            label: 'Месяц',
            onTap: _openMonthPicker,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPickerField(
            controller: _yearController,
            label: 'Год',
            onTap: _openYearPicker,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return ModalTextField(
      controller: controller,
      label: label,
      hintText: label,
      readOnly: true,
      onTap: onTap,
      suffixIcon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(AppColors.uiBorder),
      ),
      suffixIconConstraints: const BoxConstraints(minHeight: 24, minWidth: 24),
    );
  }

  Future<void> _openMonthPicker() async {
    final options = List.generate(
      12,
      (index) => _SelectionItem(value: index + 1, label: _monthName(index + 1)),
    );

    final selected = await _showSelectionSheet<int>(
      title: 'Выберите месяц',
      options: options,
      currentValue: _selectedMonth,
    );

    if (selected != null) {
      setState(() {
        _selectedMonth = selected;
        _updateDateControllers();
      });
      _reloadAll();
    }
  }

  Future<void> _openYearPicker() async {
    final currentYear = DateTime.now().year;
    final options = List.generate(7, (index) {
      final value = currentYear - 3 + index;
      return _SelectionItem(value: value, label: value.toString());
    });

    final selected = await _showSelectionSheet<int>(
      title: 'Выберите год',
      options: options,
      currentValue: _selectedYear,
    );

    if (selected != null) {
      setState(() {
        _selectedYear = selected;
        _updateDateControllers();
      });
      _reloadAll();
    }
  }

  Future<T?> _showSelectionSheet<T>({
    required String title,
    required List<_SelectionItem<T>> options,
    T? currentValue,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.value == currentValue;
                      return ListTile(
                        title: Text(option.label),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Color(AppColors.primary),
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(option.value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomeTab() {
    return BlocBuilder<BudgetIncomeBloc, BudgetIncomeState>(
      builder: (context, state) {
        if (state is BudgetIncomeLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is BudgetIncomeError) {
          return Center(child: Text(state.message));
        }
        if (state is BudgetIncomeLoaded) {
          final items = state.incomes;
          return _BudgetEntriesList(
            isIncome: true,
            entries: items
                .map(
                  (entry) => _BudgetEntryData(
                    id: entry.id,
                    comment: entry.comment,
                    investorName: entry.investorName,
                    amount: entry.amount,
                    createdAt: entry.createdAt,
                  ),
                )
                .toList(),
            currentPage: state.currentPage,
            totalPages: state.totalPages,
            onRefresh: () => _loadIncome(page: state.currentPage),
            onPageSelected: (page) => _loadIncome(page: page),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildExpenseTab() {
    return BlocBuilder<BudgetExpenseBloc, BudgetExpenseState>(
      builder: (context, state) {
        if (state is BudgetExpenseLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is BudgetExpenseError) {
          return Center(child: Text(state.message));
        }
        if (state is BudgetExpenseLoaded) {
          final items = state.expenses;
          return _BudgetEntriesList(
            isIncome: false,
            entries: items
                .map(
                  (entry) => _BudgetEntryData(
                    id: entry.id,
                    comment: entry.comment,
                    investorName: null,
                    amount: entry.amount,
                    createdAt: entry.createdAt,
                  ),
                )
                .toList(),
            currentPage: state.currentPage,
            totalPages: state.totalPages,
            onRefresh: () => _loadExpense(page: state.currentPage),
            onPageSelected: (page) => _loadExpense(page: page),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SelectionItem<T> {
  final T value;
  final String label;

  _SelectionItem({required this.value, required this.label});
}

class _BudgetEntriesList extends StatelessWidget {
  final bool isIncome;
  final List<_BudgetEntryData> entries;
  final int currentPage;
  final int totalPages;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onPageSelected;

  const _BudgetEntriesList({
    required this.isIncome,
    required this.entries,
    required this.currentPage,
    required this.totalPages,
    required this.onRefresh,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = entries.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: Refresher(
            onRefresh: onRefresh,
            content: hasData
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemBuilder: (_, index) {
                      final entry = entries[index];
                      return _BudgetEntryCard(
                        entry: entry,
                        isIncome: isIncome,
                        onTap: null,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: entries.length,
                  )
                : const Center(
                    child: Text(
                      'Нет данных',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _BudgetEntryCard extends StatelessWidget {
  final _BudgetEntryData entry;
  final bool isIncome;
  final VoidCallback? onTap;

  const _BudgetEntryCard({
    required this.entry,
    required this.isIncome,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isIncome
        ? const Color(AppColors.primary)
        : const Color(0xFFD8575B);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 168),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000809),
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: Color(0x05000809),
                  offset: Offset(0, 0),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Id: ${entry.id}',
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w400,
                        color: const Color(0xFF6B717C),
                        height: 24 / 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.createdAt != null
                          ? DateFormat('dd.MM.yyyy').format(entry.createdAt!)
                          : '—',
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w400,
                        color: const Color(0xFF6B717C),
                        height: 24 / 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  entry.displayTitle,
                  style: AppStyle.manrope(
                    size: 16,
                    weight: FontWeight.w500,
                    color: const Color(AppColors.black),
                    height: 24 / 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  'Сумма',
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w400,
                    color: const Color(0xFF6B717C),
                    height: 24 / 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(
                    locale: 'ru_RU',
                    symbol: '₽',
                    decimalDigits: 0,
                  ).format(entry.amount),
                  style: AppStyle.manrope(
                    size: 22,
                    weight: FontWeight.w500,
                    color: accent,
                    height: 24 / 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetEntryData {
  final int id;
  final String? comment;
  final String? investorName;
  final double amount;
  final DateTime? createdAt;

  _BudgetEntryData({
    required this.id,
    required this.comment,
    required this.investorName,
    required this.amount,
    required this.createdAt,
  });

  String get displayTitle {
    if (investorName != null && investorName!.trim().isNotEmpty) {
      return investorName!.trim();
    }
    if (comment == null || comment!.trim().isEmpty) {
      return 'Нет комментария';
    }
    return comment!;
  }
}
