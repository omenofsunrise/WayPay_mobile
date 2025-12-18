import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/utils/bottom_nav_controller.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_picker_modal.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';
import 'package:waypay_mobile/features/payment/presentation/bloc/expected/payment_bloc.dart';

class PaymentIncomeScreen extends StatefulWidget {
  const PaymentIncomeScreen({super.key});

  @override
  State<PaymentIncomeScreen> createState() => _PaymentIncomeScreenState();
}

class _PaymentIncomeScreenState extends State<PaymentIncomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _investorFilter;
  int? _selectedMonth;
  int? _selectedYear;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadPayments(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 200 && !_isLoadingMore) {
      final state = context.read<PaymentBloc>().state;
      if (state is PaymentLoaded && state.hasMoreData) {
        _isLoadingMore = true;
        context.read<PaymentBloc>().add(
          LoadPayment(
            refresh: false,
            page: state.currentPage + 1,
            search: _currentSearch,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
          ),
        );
      }
    }
  }

  String get _currentSearch => _searchController.text.trim();

  bool get _hasFilters =>
      _selectedMonth != null ||
      _selectedYear != null ||
      (_investorFilter != null && _investorFilter!.isNotEmpty);

  void _loadPayments({required bool refresh}) {
    debugPrint(
      '[PAYMENT_INCOME] loading payments: '
      'refresh=$refresh search=${_currentSearch} '
      'investor=$_investorFilter month=$_selectedMonth year=$_selectedYear '
      'dateFrom=$_dateFrom dateTo=$_dateTo',
    );
    context.read<PaymentBloc>().add(
      LoadPayment(
        refresh: refresh,
        page: refresh ? 1 : null,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        investorNickname: _investorFilter,
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadPayments(refresh: true);
    });
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_PaymentFilterResult>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.white.withOpacity(0.7),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PaymentIncomeFilterSheet(
        initialInvestor: _investorFilter,
        initialMonth: _selectedMonth,
        initialYear: _selectedYear,
      ),
    );

    if (result != null) {
      setState(() {
        _investorFilter = result.investor;
        _selectedMonth = result.month;
        _selectedYear = result.year;
        if (_selectedMonth != null && _selectedYear != null) {
          _dateFrom = DateTime(_selectedYear!, _selectedMonth!, 1);
          _dateTo = DateTime(_selectedYear!, _selectedMonth! + 1, 0);
        } else {
          _dateFrom = null;
          _dateTo = null;
        }
      });
      _loadPayments(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: BlocListener<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentLoaded || state is PaymentError) {
                if (state is PaymentError) {
                  debugPrint('[PAYMENT_INCOME] error: ${state.message}');
                }
                _isLoadingMore = false;
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(
                  title: 'Доходы от платежей',
                  showBackButton: true,
                  showNotifications: true,
                ),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _loadPayments(refresh: true);
                    },
                    child: BlocBuilder<PaymentBloc, PaymentState>(
                      builder: (context, state) {
                        if (state is PaymentInitial) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is PaymentError) {
                          return Center(
                            child: Text(
                              state.message,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        if (state is PaymentLoaded) {
                          if (state.payment.isEmpty) {
                            return const Center(
                              child: Text('Платежи не найдены'),
                            );
                          }
                          return ListView.separated(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                state.payment.length +
                                (state.hasMoreData ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index >= state.payment.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final payment = state.payment[index];
                              return _PaymentIncomeCard(payment: payment);
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Поиск',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilterButton(onTap: _openFilterSheet, isActive: _hasFilters),
      ],
    );
  }
}

class _PaymentIncomeCard extends StatelessWidget {
  const _PaymentIncomeCard({required this.payment});

  final PaymentItemModel payment;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '',
      decimalDigits: 0,
    );
    final date = DateFormat(
      'dd.MM.yyyy',
    ).format(DateTime.parse(payment.paymentDate));
    final paymentText = '${formatter.format(payment.paymentAmount)}₽';
    final incomeText = '${formatter.format(payment.income)}₽';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                'Договор № ${payment.creditId}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.uiBorder),
                ),
              ),
              const Spacer(),
              Text(
                'от $date',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.uiBorder),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            payment.clientFullName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.black),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Платёж',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Доход',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  paymentText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.black),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  incomeText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.black),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentFilterResult {
  final int? month;
  final int? year;
  final String? investor;

  _PaymentFilterResult({this.month, this.year, this.investor});
}

class PaymentIncomeFilterSheet extends StatelessWidget {
  const PaymentIncomeFilterSheet({
    super.key,
    this.initialInvestor,
    this.initialMonth,
    this.initialYear,
  });

  final String? initialInvestor;
  final int? initialMonth;
  final int? initialYear;

  @override
  Widget build(BuildContext context) {
    return FilterSheet(
      child: _PaymentFilterForm(
        initialInvestor: initialInvestor,
        initialMonth: initialMonth,
        initialYear: initialYear,
      ),
    );
  }
}

class _PaymentFilterForm extends StatefulWidget {
  const _PaymentFilterForm({
    this.initialInvestor,
    this.initialMonth,
    this.initialYear,
  });

  final String? initialInvestor;
  final int? initialMonth;
  final int? initialYear;

  @override
  State<_PaymentFilterForm> createState() => _PaymentFilterFormState();
}

class _PaymentFilterFormState extends State<_PaymentFilterForm> {
  late final TextEditingController _investorController;
  late final TextEditingController _monthController;
  late final TextEditingController _yearController;
  int? _month;
  int? _year;
  final DateFormat _monthFormatter = DateFormat('LLLL', 'ru');

  @override
  void initState() {
    super.initState();
    _investorController = TextEditingController(
      text: widget.initialInvestor ?? '',
    );
    _monthController = TextEditingController();
    _yearController = TextEditingController();
    _month = widget.initialMonth;
    _year = widget.initialYear;
    _monthController.text = _month == null ? '' : _monthName(_month!);
    _yearController.text = _year?.toString() ?? '';
  }

  @override
  void dispose() {
    _investorController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  String _monthName(int month) {
    return _monthFormatter
        .format(DateTime(2020, month))
        .replaceFirstMapped(RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase());
  }

  Future<void> _pickMonth() async {
    BottomNavController.instance.hide();
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _OptionSheet(
        title: 'Выберите месяц',
        options: List.generate(
          12,
          (index) =>
              _OptionItem(value: index + 1, label: _monthName(index + 1)),
        ),
        selected: _month,
      ),
    );
    BottomNavController.instance.show();
    if (result != null) {
      setState(() {
        _month = result;
        _monthController.text = _monthName(result);
      });
    }
  }

  Future<void> _pickYear() async {
    final currentYear = DateTime.now().year;
    final years = List.generate(6, (index) => currentYear - 2 + index);
    BottomNavController.instance.hide();
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _OptionSheet(
        title: 'Выберите год',
        options: years
            .map((year) => _OptionItem(value: year, label: year.toString()))
            .toList(),
        selected: _year,
      ),
    );
    BottomNavController.instance.show();
    if (result != null) {
      setState(() {
        _year = result;
        _yearController.text = result.toString();
      });
    }
  }

  Future<void> _selectInvestor() async {
    final result = await showModalBottomSheet<InvestorsModel>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider(
        create: (_) => InvestorsBloc(),
        child: const InvestorPickerModal(
          includeInvestor: true,
          includePool: false,
          title: 'Выберите инвестора',
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _investorController.text = result.nickname;
      });
    }
  }

  void _apply() {
    Navigator.of(context).pop(
      _PaymentFilterResult(
        month: _month,
        year: _year,
        investor: _investorController.text.trim().isEmpty
            ? null
            : _investorController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValues =
        _month != null ||
        _year != null ||
        _investorController.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ModalTextField(
                controller: _monthController,
                label: 'Месяц',
                hintText: 'Месяц',
                readOnly: true,
                onTap: _pickMonth,
                suffixIcon: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModalTextField(
                controller: _yearController,
                label: 'Год',
                hintText: 'Год',
                readOnly: true,
                onTap: _pickYear,
                suffixIcon: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ModalTextField(
          controller: _investorController,
          label: 'Выберите инвестора',
          hintText: 'Выберите инвестора',
          readOnly: true,
          onTap: _selectInvestor,
          suffixIcon: const Icon(Icons.keyboard_arrow_down),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: DefaultButton(
                text: 'Отменить',
                color: const Color(0xFFB8BEC8),
                textColor: const Color(AppColors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultButton(
                text: 'Применить',
                color: hasValues
                    ? const Color(AppColors.primary)
                    : const Color(0xFFA8DADB),
                textColor: Colors.white,
                onPressed: hasValues ? _apply : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionSheet extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<_OptionItem> options;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final option = options[index];
                final isActive = option.value == selected;
                return ListTile(
                  title: Text(option.label),
                  trailing: isActive
                      ? const Icon(Icons.check, color: Color(AppColors.primary))
                      : null,
                  onTap: () => Navigator.of(context).pop(option.value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionItem {
  const _OptionItem({required this.value, required this.label});

  final int value;
  final String label;
}
