import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investor_report_screen.dart';
import 'package:waypay_styles/waypay_styles.dart';

class InvestorsScreen extends StatefulWidget {
  const InvestorsScreen({super.key});

  @override
  State<InvestorsScreen> createState() => _InvestorsScreenState();
}

class _InvestorsScreenState extends State<InvestorsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<InvestorsBloc>();
      if (bloc.state is! InvestorsLoaded) {
        bloc.add(LoadInvestorsEvent(refresh: true));
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (query.isEmpty) {
        context.read<InvestorsBloc>().add(ResetSearchInvestorsEvent());
      } else {
        context.read<InvestorsBloc>().add(SearchInvestorsEvent(query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'Инвесторы',
                showBackButton: true,
                showNotifications: false,
              ),
              const SizedBox(height: 16),
              SearchField(
                controller: _searchController,
                hintText: 'Поиск',
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<InvestorsBloc, InvestorsState>(
                  builder: (context, state) {
                    if (state is InvestorsInitial ||
                        state is InvestorsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is InvestorsError) {
                      return _InvestorsError(
                        message: state.message,
                        onRetry: () => context.read<InvestorsBloc>().add(
                          LoadInvestorsEvent(refresh: true),
                        ),
                      );
                    }
                    if (state is InvestorsLoaded) {
                      if (state.investors.isEmpty) {
                        return const Center(
                          child: Text(
                            'Нет инвесторов по текущим параметрам',
                            style: TextStyle(color: Color(AppColors.uiBorder)),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification &&
                              notification.metrics.pixels >=
                                  notification.metrics.maxScrollExtent - 200 &&
                              state.hasMoreData) {
                            context.read<InvestorsBloc>().add(
                              LoadInvestorsEvent(page: state.currentPage + 1),
                            );
                          }
                          return false;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemBuilder: (context, index) {
                            if (index >= state.investors.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final investor = state.investors[index];
                            return _InvestorCard(investor: investor);
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemCount:
                              state.investors.length +
                              ((state.hasMoreData) ? 1 : 0),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestorCard extends StatelessWidget {
  const _InvestorCard({required this.investor});

  final InvestorsModel investor;

  String _formatCurrency(num value) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _estimateEndDate(DateTime? start) {
    if (start == null) return '—';
    return _formatDate(start.add(const Duration(days: 90)));
  }

  @override
  Widget build(BuildContext context) {
    final createdAtText = _formatDate(investor.createdAt);
    final endDateText = _estimateEndDate(investor.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvestorReportScreen(initialInvestor: investor),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ID: ${investor.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(AppColors.uiBorder),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      createdAtText == '—' ? '' : 'от $createdAtText',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(AppColors.uiBorder),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  investor.nickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InfoColumn(
                        label: 'Касса',
                        value: _formatCurrency(investor.balance),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _InfoColumn(
                        label: 'Дата окончания договора',
                        value: endDateText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(AppColors.uiBorder),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.black),
          ),
        ),
      ],
    );
  }
}

class _InvestorsError extends StatelessWidget {
  const _InvestorsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
