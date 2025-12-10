import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/features/payment/presentation/cubit/payment_schedule_cubit.dart';
import 'package:waypay_mobile/features/payment/presentation/widgets/payment_schedule_card.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';

class PaymentAnalyticsScreen extends StatelessWidget {
  const PaymentAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasAccess =
        UserStorage().hasPermissionSync([Permission.viewAnalytic]);

    if (!hasAccess) {
      return Scaffold(
        backgroundColor: const Color(AppColors.background),
        body: const SafeArea(
          child: Center(
            child: Text(
              'Нет доступа к аналитике платежей',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(AppColors.darkGrey)),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'Аналитика платежей',
                showBackButton: true,
                showNotifications: true,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<PaymentScheduleCubit, PaymentScheduleState>(
                  builder: (context, state) {
                    if (state is PaymentScheduleLoading ||
                        state is PaymentScheduleInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is PaymentScheduleError) {
                      return _ErrorState(
                        message: state.message,
                        onRetry: () => context
                            .read<PaymentScheduleCubit>()
                            .load(year: DateTime.now().year),
                      );
                    }
                    if (state is PaymentScheduleNoAccess) {
                      return const Center(
                        child: Text(
                          'Нет доступа к аналитике платежей',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(AppColors.darkGrey)),
                        ),
                      );
                    }
                    if (state is PaymentScheduleLoaded) {
                      final summaries = state.summaries;
                      if (summaries.isEmpty) {
                        return const Center(
                          child: Text(
                            'Нет данных аналитики',
                            style: TextStyle(color: Color(AppColors.darkGrey)),
                          ),
                        );
                      }
                      return Refresher(
                        onRefresh: () async => context
                            .read<PaymentScheduleCubit>()
                            .load(year: DateTime.now().year),
                        content: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemBuilder: (context, index) {
                            final summary = summaries[index];
                            return PaymentScheduleCard(summary: summary);
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemCount: summaries.length,
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
