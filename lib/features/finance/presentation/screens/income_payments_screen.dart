import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/core/widgets/refresh.dart';
import 'package:waypay/features/finance/presentation/widgets/payment_card.dart';
import 'package:waypay/features/finance/presentation/widgets/simple_dropdown.dart';
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
    _loadPaymentsByMonthYear();
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
      ),
      body: ValueListenableBuilder<EmployeeRole?>(
        valueListenable: UserStorage().roleNotifier,
        builder: (context, role, _) {
          return Column(
            children: [
              Container(
                color: const Color(AppColors.primary),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<PaymentBloc, PaymentState>(
                      builder: (context, state) {
                        final total = state is PaymentLoaded
                            ? state.totalCount
                            : 0;
                        return Text(
                          'Всего платежей: $total',
                          style: AppStyle.inter(
                            size: 24,
                            weight: FontWeight.w300,
                            color: const Color(AppColors.background),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SimpleDropdown<int>(
                            items: List.generate(12, (index) => index + 1),
                            labelBuilder: (month) {
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
                              return monthNames[month - 1];
                            },
                            initialValue: _selectedMonth,
                            onChanged: (month) {
                              if (month == null) return;
                              setState(() => _selectedMonth = month);
                              _loadPaymentsByMonthYear();
                            },
                          ),
                        ),

                        Expanded(
                          child: SimpleDropdown<int>(
                            items: List.generate(5, (index) => 2023 + index),
                            labelBuilder: (year) => '$year',
                            initialValue: _selectedYear,
                            onChanged: (year) {
                              if (year == null) return;
                              setState(() => _selectedYear = year);
                              _loadPaymentsByMonthYear();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Поиск по клиенту...',
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
                            final bloc = context.read<PaymentBloc>();
                            if (value.isNotEmpty) {
                              bloc.add(SearchPayment(value));
                            } else {
                              _loadPaymentsByMonthYear();
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<PaymentBloc, PaymentState>(
                      builder: (context, state) {
                        int totalIncome = 0;
                        int totalPayments = 0;
                        if (state is PaymentLoaded) {
                          totalIncome = state.totalIncome;
                          totalPayments = state.totalPayments.toInt();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Всего доход: $totalIncome ₽',
                              style: AppStyle.manrope(
                                size: 14,
                                weight: FontWeight.w400,
                                color: Color(AppColors.background),
                              ),
                            ),
                            Text(
                              'Всего выплат: $totalPayments ₽',
                              style: AppStyle.manrope(
                                size: 14,
                                weight: FontWeight.w400,
                                color: Color(AppColors.background),
                              ),
                            ),
                          ],
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
                                    LoadPayment(page: page, refresh: true),
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
