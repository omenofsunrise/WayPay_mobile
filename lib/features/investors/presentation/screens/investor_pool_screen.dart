import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investor_pool_bloc.dart';
import 'package:waypay_mobile/routes/routes.dart';

class InvestorPoolScreen extends StatefulWidget {
  const InvestorPoolScreen({super.key});

  @override
  State<InvestorPoolScreen> createState() => _InvestorPoolScreenState();
}

class _InvestorPoolScreenState extends State<InvestorPoolScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InvestorPoolBloc>().add(LoadInvestorPool(refresh: true));
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
        context.read<InvestorPoolBloc>().add(ResetInvestorPool());
      } else {
        context.read<InvestorPoolBloc>().add(SearchInvestorPool(query));
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
                title: 'Пул инвесторов',
                showBackButton: true,
                showNotifications: true,
              ),
              const SizedBox(height: 16),
              SearchField(
                controller: _searchController,
                hintText: 'Поиск',
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<InvestorPoolBloc, InvestorPoolState>(
                  builder: (context, state) {
                    if (state is InvestorPoolInitial ||
                        state is InvestorPoolLoading &&
                            (state is! InvestorPoolLoaded)) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is InvestorPoolError) {
                      return _InvestorPoolError(
                        message: state.message,
                        onRetry: () => context
                            .read<InvestorPoolBloc>()
                            .add(LoadInvestorPool(refresh: true)),
                      );
                    }
                    if (state is InvestorPoolLoaded) {
                      if (state.items.isEmpty) {
                        return const Center(
                          child: Text(
                            'Нет пулов инвесторов по текущим параметрам',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(AppColors.darkGrey)),
                          ),
                        );
                      }
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification &&
                              notification.metrics.pixels >=
                                  notification.metrics.maxScrollExtent - 200 &&
                              state.hasMore) {
                            context.read<InvestorPoolBloc>().add(
                                  LoadInvestorPool(
                                    page: state.currentPage + 1,
                                  ),
                                );
                          }
                          return false;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount:
                              state.items.length + (state.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final pool = state.items[index];
                            return _InvestorPoolCard(pool: pool);
                          },
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

class _InvestorPoolCard extends StatelessWidget {
  const _InvestorPoolCard({required this.pool});

  final InvestorPoolModel pool;

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatCurrency(num value) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.pushNamed(
          Routes.investorPoolDetailScreen.toName,
          extra: pool,
        ),
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
                      'ID: ${pool.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(AppColors.darkGrey),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      pool.activeUntil != null
                          ? 'от ${_formatDate(pool.activeUntil)}'
                          : '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(AppColors.darkGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  pool.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _InfoColumn(
                        label: 'Дата создания',
                        value: _formatDate(pool.createdAt),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _InfoColumn(
                        label: 'Касса',
                        value: _formatCurrency(pool.balance),
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
            color: Color(AppColors.darkGrey),
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

class _InvestorPoolError extends StatelessWidget {
  const _InvestorPoolError({required this.message, required this.onRetry});

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
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
