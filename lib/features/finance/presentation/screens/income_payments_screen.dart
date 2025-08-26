import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/core/widgets/refresh.dart';
import 'package:waypay/features/finance/presentation/widgets/payment_card.dart';
import 'package:waypay/features/payment/presentation/bloc/expected/payment_bloc.dart';
import 'package:waypay/features/profile/data/models/employee.dart';

class IncomePaymentsScreen extends StatefulWidget {
  const IncomePaymentsScreen({super.key});

  @override
  State<IncomePaymentsScreen> createState() => _IncomePaymentsScreenState();
}

class _IncomePaymentsScreenState extends State<IncomePaymentsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  late DateTime _dateFrom;
  late DateTime _dateTo;

  @override
  void initState() {
    super.initState();
    _updateDates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentsByMonthYear();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _updateDates() {
    _dateFrom = DateTime(_selectedYear, _selectedMonth, 1).toUtc();
    _dateTo = DateTime(_selectedYear, _selectedMonth + 1, 0).toUtc();
  }

  void _loadPaymentsByMonthYear() {
    _updateDates();
    context.read<PaymentBloc>().add(
      LoadPayment(refresh: true, dateFrom: _dateFrom, dateTo: _dateTo),
    );
  }

  void _openFilterModal(BuildContext context) {
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;
    final TextEditingController tempController = TextEditingController(
      text: _searchController.text,
    );

    final paymentBloc = context.read<PaymentBloc>();

    showDialog(
      context: context,
      builder: (context) {
        return AppModal(
          title: 'Фильтры',
          backgroundColor: const Color(AppColors.background),
          contentPadding: const EdgeInsets.all(16),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: tempController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Поиск по клиенту...',
                      hintStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        if (value.trim().isNotEmpty) {
                          paymentBloc.add(SearchPayment(value.trim()));
                        } else {
                          _updateDates();
                          paymentBloc.add(
                            LoadPayment(
                              refresh: true,
                              dateFrom: _dateFrom,
                              dateTo: _dateTo,
                            ),
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

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
                                  child: Text(_monthName(m)),
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
                          items: List.generate(5, (i) => 2023 + i)
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
                tempController.clear();
                tempMonth = DateTime.now().month;
                tempYear = DateTime.now().year;

                setState(() {
                  _selectedMonth = tempMonth;
                  _selectedYear = tempYear;
                  _searchController.clear();
                });

                _updateDates();
                paymentBloc.add(
                  LoadPayment(
                    refresh: true,
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                  ),
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
                  _selectedMonth = tempMonth;
                  _selectedYear = tempYear;
                  _searchController.text = tempController.text;
                });

                _updateDates();
                final query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  paymentBloc.add(SearchPayment(query));
                } else {
                  paymentBloc.add(
                    LoadPayment(
                      refresh: true,
                      dateFrom: _dateFrom,
                      dateTo: _dateTo,
                    ),
                  );
                }

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  String _monthName(int m) {
    const monthNames = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return monthNames[m - 1];
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
          'Платежи',
          style: AppStyle.medium20.copyWith(
            color: const Color(AppColors.background),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: () => _openFilterModal(context),
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: BlocBuilder<PaymentBloc, PaymentState>(
                    builder: (context, state) {
                      if (state is PaymentInitial) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is PaymentError) {
                        return Center(child: Text('Ошибка: ${state.message}'));
                      }

                      if (state is PaymentLoaded) {
                        if (state.payment.isEmpty) {
                          return const Center(
                            child: Text('Платежи не найдены'),
                          );
                        }

                        return Column(
                          children: [
                            Expanded(
                              child: Refresher(
                                onRefresh: () async {
                                  context.read<PaymentBloc>().add(
                                    LoadPayment(
                                      refresh: true,
                                      dateFrom: _dateFrom,
                                      dateTo: _dateTo,
                                      page: state.currentPage,
                                    ),
                                  );
                                },
                                content: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.payment.length,
                                  itemBuilder: (context, index) {
                                    final payment = state.payment[index];
                                    return PaymentCard(payment: payment);
                                  },
                                ),
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
                                  context.read<PaymentBloc>().add(
                                    LoadPayment(
                                      page: page,
                                      refresh: true,
                                      dateFrom: _dateFrom,
                                      dateTo: _dateTo,
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
}
