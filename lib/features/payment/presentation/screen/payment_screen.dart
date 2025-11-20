import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/core/widgets/app_modal.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/schedule_model.dart';
import 'package:waypay_mobile/features/payment/presentation/bloc/expected/payment_bloc.dart';
import 'package:waypay_mobile/features/payment/presentation/cubit/payment_schedule_cubit.dart';
import 'package:waypay_mobile/features/payment/presentation/cubit/payment_history_cubit.dart';
import 'package:waypay_mobile/features/payment/presentation/cubit/schedule_preview_cubit.dart';
import 'package:waypay_mobile/features/payment/presentation/widgets/payment_preview_card.dart';
import 'package:waypay_mobile/features/payment/presentation/widgets/payment_schedule_card.dart';
import 'package:waypay_mobile/routes/routes.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PaymentBloc>().add(
        LoadPayment(refresh: true, page: 1, pageSize: 10),
      );
      context.read<PaymentScheduleCubit>().load(year: DateTime.now().year);
      context.read<SchedulePreviewCubit>().load(limit: 2);
      context.read<PaymentHistoryCubit>().load(limit: 2);
    });
  }

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.phoneAuthScreen.toName);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterModal(BuildContext context) {
    final paymentBloc = context.read<PaymentBloc>();
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
                hintText: 'Поиск по имени...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  final q = value.trim();
                  if (q.isNotEmpty) {
                    paymentBloc.add(SearchPayment(q, pageSize: 10));
                  } else {
                    paymentBloc.add(
                      LoadPayment(refresh: true, page: 1, pageSize: 10),
                    );
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
              paymentBloc.add(
                LoadPayment(refresh: true, page: 1, pageSize: 10),
              );
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
                paymentBloc.add(SearchPayment(q, pageSize: 10));
              } else {
                paymentBloc.add(
                  LoadPayment(refresh: true, page: 1, pageSize: 10),
                );
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
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
                title: 'Платежи',
                showBackButton: true,
                showNotifications: true,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<PaymentBloc, PaymentState>(
                  builder: (context, state) {
                    if (state is PaymentInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is PaymentError) {
                      return _buildErrorState(state.message);
                    }
                    if (state is PaymentLoaded) {
                      return Refresher(
                        onRefresh: () async {
                          context.read<PaymentBloc>().add(
                                LoadPayment(
                                  refresh: true,
                                  page: 1,
                                  pageSize: 10,
                                  search: _searchController.text.isEmpty
                                      ? null
                                      : _searchController.text,
                                ),
                              );
                          await context
                              .read<SchedulePreviewCubit>()
                              .load(limit: 2);
                          await context
                              .read<PaymentHistoryCubit>()
                              .load(limit: 2);
                        },
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAnalyticsSection(),
                              const SizedBox(height: 24),
                              _buildExpectedPaymentsSection(),
                              const SizedBox(height: 24),
                              _buildHistorySection(),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (message.contains('Сессия')) {
                  _logout();
                } else {
                  context.read<PaymentBloc>().add(
                    LoadPayment(refresh: true, page: 1, pageSize: 10),
                  );
                }
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Аналитика',
          actionText: 'Вся аналитика',
          onPressed: () {
            context.pushNamed(Routes.paymentAnalyticsScreen.toName);
          },
        ),
        const SizedBox(height: 12),
        BlocBuilder<PaymentScheduleCubit, PaymentScheduleState>(
          builder: (context, state) {
            if (state is PaymentScheduleLoading ||
                state is PaymentScheduleInitial) {
              return _analyticsContainer(
                const Center(child: CircularProgressIndicator()),
              );
            }
            if (state is PaymentScheduleNoAccess) {
              return _analyticsContainer(
                const Text(
                  'У вас нет доступа к аналитике платежей.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            if (state is PaymentScheduleError) {
              return _analyticsContainer(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context
                          .read<PaymentScheduleCubit>()
                          .load(year: DateTime.now().year),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }
            if (state is PaymentScheduleLoaded && state.summaries.isNotEmpty) {
              return PaymentScheduleCard(summary: state.summaries.first);
            }
            return _analyticsContainer(
              const Text(
                'Нет данных об аналитике платежей',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(AppColors.darkGrey)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpectedPaymentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Ожидаемые',
          actionText: 'Все платежи',
          onPressed: () {
            context.pushNamed(Routes.scheduleScreen.toName);
          },
        ),
        const SizedBox(height: 12),
        BlocBuilder<SchedulePreviewCubit, SchedulePreviewState>(
          builder: (context, state) {
            if (state is SchedulePreviewLoading ||
                state is SchedulePreviewInitial) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is SchedulePreviewError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context
                        .read<SchedulePreviewCubit>()
                        .load(limit: 2),
                    child: const Text('Повторить'),
                  ),
                ],
              );
            }
            if (state is SchedulePreviewLoaded) {
              final schedules = state.schedules.take(2).toList();
              if (schedules.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Нет ожидаемых платежей',
                    style: TextStyle(color: Color(AppColors.darkGrey)),
                  ),
                );
              }
              return Column(
                children: schedules
                    .map(
                      (schedule) => PaymentPreviewCard(
                        payment: _scheduleToPaymentPreview(schedule),
                        onTap: () => context.pushNamed(
                          Routes.paymentDetailScreen.toName,
                          extra: schedule,
                        ),
                      ),
                    )
                    .toList(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  PaymentItemModel _scheduleToPaymentPreview(ScheduleModel schedule) {
    return PaymentItemModel(
      id: schedule.id,
      creditId: schedule.creditId,
      paymentAmount: schedule.paymentAmount,
      paymentDate: schedule.paymentDate,
      type: PaymentType.cash,
      accepted: false,
      clientFullName: schedule.clientName,
      investorNickname: null,
      employeeFullName: null,
      income: 0,
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'История',
          actionText: 'Вся история',
          onPressed: () =>
              context.pushNamed(Routes.paymentHistoryScreen.toName),
        ),
        const SizedBox(height: 12),
        BlocBuilder<PaymentHistoryCubit, PaymentHistoryState>(
          builder: (context, state) {
            if (state is PaymentHistoryLoading ||
                state is PaymentHistoryInitial) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is PaymentHistoryError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context
                        .read<PaymentHistoryCubit>()
                        .load(limit: 2),
                    child: const Text('Повторить'),
                  ),
                ],
              );
            }
            if (state is PaymentHistoryLoaded) {
              final payments = state.payments.take(3).toList();
              if (payments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'История платежей пуста',
                    style: TextStyle(color: Color(AppColors.darkGrey)),
                  ),
                );
              }
              return Column(
                children: payments
                    .map(
                      (payment) => PaymentPreviewCard(
                        payment: payment,
                        showStatus: true,
                        onTap: () => context.pushNamed(
                          Routes.paymentDetailScreen.toName,
                          extra: payment,
                        ),
                      ),
                    )
                    .toList(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _analyticsContainer(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
      child: child,
    );
  }

  Widget _sectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(AppColors.black),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            children: [
              Text(
                actionText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                  color: Color(AppColors.primary),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
