import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/form_modal/labeled_container.dart';
import 'package:waypay/features/profile/data/models/employee.dart';

import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/features/finance/data/data_source/budget_remote_data_source.dart';
import 'package:waypay/features/finance/presentation/bloc/budget/budget_expense_bloc.dart';
import 'package:waypay/features/finance/presentation/bloc/budget/budget_income_bloc.dart';

class BudgetCard extends StatelessWidget {
  final int id;
  final double amount;
  final String? comment;
  final DateTime? createdAt;
  final bool isIncome;

  const BudgetCard({
    super.key,
    required this.id,
    required this.amount,
    this.comment,
    required this.createdAt,
    this.isIncome = true,
  });

  String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final userStorage = UserStorage();

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AppModal(
            backgroundColor: Color(AppColors.background),
            title: isIncome ? 'Детали прихода' : 'Детали расхода',
            menuItems: (userStorage.hasViewContent([EmployeeRole.superAdmin, EmployeeRole.director]))
                ? [
                    PopupMenuItem(
                      child: const Text('Удалить'),
                      onTap: () async {
                        context.pop();

                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: Color(AppColors.background),
                            title: const Text('Удаление'),
                            content: const Text('Удалить эту запись?'),
                            actions: [
                              TextButton(onPressed: () => context.pop(false), child: const Text('Отмена')),
                              TextButton(onPressed: () => context.pop(true), child: const Text('Удалить')),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );
                          try {
                            if (isIncome) {
                              await getIt<BudgetRemoteDataSource>().deleteBudgetIncome(id);
                              if (context.mounted) {
                                Navigator.pop(context);
                                context.read<BudgetIncomeBloc>().add(LoadBudgetIncomeEvent());
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(const SnackBar(content: Text('Приход удален')));
                              }
                            } else {
                              await getIt<BudgetRemoteDataSource>().deleteBudgetOutcome(id);
                              if (context.mounted) {
                                Navigator.pop(context); // Закрыть загрузку
                                context.read<BudgetExpenseBloc>().add(LoadBudgetExpenseEvent());
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(const SnackBar(content: Text('Расход удален')));
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: Color(AppColors.background),
                                  title: const Text('Ошибка'),
                                  content: Text('Не удалось удалить.\n$e'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ок')),
                                  ],
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ]
                : null,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledContainer(label: 'Сумма', text: '${amount.toStringAsFixed(0)} ₽'),
                LabeledContainer(label: 'Дата', text: createdAt != null ? formatDate(createdAt!) : 'не указана'),
                LabeledContainer(label: 'Комментарий', text: (comment?.trim().isEmpty ?? true) ? '-' : comment!),
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                createdAt != null ? formatDate(createdAt!) : "Дата не указана",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            Text(
              '${amount.toStringAsFixed(0)} ₽',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
