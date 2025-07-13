import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/models/employee_role.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/form_modal/app_form_modal.dart';
import 'package:waypay/core/widgets/form_modal/form_field_config.dart';
import 'package:waypay/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay/features/investors/data/models/investors_model.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay/features/investors/presentation/bloc/investors_bloc.dart';

class InvestorCard extends StatelessWidget {
  final InvestorsModel investor;

  const InvestorCard({super.key, required this.investor});

  Future<void> _updateUserRole() async {
    final authDataSource = getIt<AuthRemoteDataSource>();
    final userStorage = getIt<UserStorage>();

    debugPrint("🔄 Обновляем роль...");

    try {
      final info = await authDataSource.getAuthInfo();
      final employee = info['employee'] as Map<String, dynamic>?;

      if (employee == null) {
        debugPrint("⚠️ Нет данных о пользователе");
        return;
      }

      final roleStr = employee['role']?.toString() ?? '';
      final role = EmployeeRoleMapper.fromApi(roleStr);
      await userStorage.saveRole(role);

      final permissionsList = (employee['permissions'] as List?) ?? [];
      final permissions = permissionsList
          .map((p) => PermissionMapper.fromApi(p.toString()))
          .toList();
      await userStorage.savePermissions(permissions);

      debugPrint("✅ Роль обновлена: $role, права: $permissions");
    } catch (e) {
      debugPrint("❌ Ошибка при обновлении роли: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = investor.balance >= 0;
    final userStorage = getIt<UserStorage>();

    return ValueListenableBuilder<EmployeeRole?>(
      valueListenable: userStorage.roleNotifier,
      builder: (context, role, _) {
        final canSeeNames = userStorage.canViewAdminContent();

        return InkWell(
          onTap: () async {
            await _updateUserRole();

            final dataSource = getIt<InvestorsRemoteDataSource>();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );

            try {
              final detailedInvestor = await dataSource.getInvestorById(
                investor.id,
              );
              context.pop();

              showDialog(
                context: context,
                builder: (_) => ValueListenableBuilder<EmployeeRole?>(
                  valueListenable: userStorage.roleNotifier,
                  builder: (context, role, _) {
                    final canSeeNames = userStorage.canViewAdminContent();
                    return AppModal(
                      title: 'Информация о инвесторе',
                      menuItems: canSeeNames
                          ? [
                              if (!detailedInvestor.isBlocked) ...[
                                PopupMenuItem(
                                  child: const Text('Добавить инвестицию'),
                                  onTap: () async {
                                    context.pop();
                                    final amountController =
                                        TextEditingController();
                                    await showDialog(
                                      context: context,
                                      builder: (_) => AppFormModal(
                                        title: 'Добавить инвестицию',
                                        fields: [
                                          FormFieldConfig(
                                            controller: amountController,
                                            label: 'Сумма',
                                            placeholder: '0.0',
                                            keyboardType: TextInputType.number,
                                          ),
                                        ],
                                        onCancel: () => context.pop(),
                                        onSave: () async {
                                          context.pop();
                                          final amount = double.tryParse(
                                            amountController.text.trim(),
                                          );
                                          if (amount == null || amount <= 0) {
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text('Ошибка'),
                                                content: const Text(
                                                  'Введите корректную сумму.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        context.pop(),
                                                    child: const Text('Ок'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            return;
                                          }

                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) => const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );

                                          try {
                                            await dataSource.addInvestment(
                                              id: investor.id,
                                              amount: amount,
                                            );
                                            context.pop();
                                            context.read<InvestorsBloc>().add(
                                              LoadInvestorsEvent(refresh: true),
                                            );
                                          } catch (e) {
                                            context.pop();
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text('Ошибка'),
                                                content: Text(
                                                  'Не удалось добавить инвестицию.\n$e',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        context.pop(),
                                                    child: const Text('Ок'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),

                                PopupMenuItem(
                                  child: const Text('Редактировать'),
                                  onTap: () async {
                                    context.pop();
                                    final nicknameController =
                                        TextEditingController(
                                          text: detailedInvestor.nickname,
                                        );
                                    final fullNameController =
                                        TextEditingController(
                                          text: detailedInvestor.fullName,
                                        );
                                    final phoneController =
                                        TextEditingController(
                                          text:
                                              detailedInvestor.phoneNumber ??
                                              '',
                                        );
                                    final pieController = TextEditingController(
                                      text: detailedInvestor.investorPie
                                          .toString(),
                                    );

                                    await showDialog(
                                      context: context,
                                      builder: (_) => AppFormModal(
                                        title: 'Редактировать инвестора',
                                        fields: [
                                          FormFieldConfig(
                                            controller: nicknameController,
                                            label: 'Никнейм',
                                            placeholder: 'Введите никнейм',
                                          ),
                                          FormFieldConfig(
                                            controller: fullNameController,
                                            label: 'ФИО',
                                            placeholder: 'Введите ФИО',
                                          ),
                                          FormFieldConfig(
                                            controller: phoneController,
                                            label: 'Телефон',
                                            placeholder: 'Введите телефон',
                                            keyboardType: TextInputType.phone,
                                          ),
                                          FormFieldConfig(
                                            controller: pieController,
                                            label: 'Доля инвестора (%)',
                                            placeholder: '0',
                                            keyboardType: TextInputType.number,
                                          ),
                                        ],
                                        onCancel: () => context.pop(),
                                        onSave: () async {
                                          context.pop();
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) => const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                          try {
                                            await dataSource.updateInvestor(
                                              id: investor.id,
                                              nickname: nicknameController.text
                                                  .trim(),
                                              fullName: fullNameController.text
                                                  .trim(),
                                              phoneNumber:
                                                  phoneController.text
                                                      .trim()
                                                      .isEmpty
                                                  ? null
                                                  : phoneController.text.trim(),
                                              investorPie:
                                                  int.tryParse(
                                                    pieController.text,
                                                  ) ??
                                                  0,
                                            );
                                            context.pop();
                                            context.read<InvestorsBloc>().add(
                                              LoadInvestorsEvent(refresh: true),
                                            );
                                          } catch (e) {
                                            context.pop();
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text('Ошибка'),
                                                content: Text(
                                                  'Не удалось обновить инвестора.\n$e',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        context.pop(),
                                                    child: const Text('Ок'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),

                                // Заблокировать
                                PopupMenuItem(
                                  child: const Text('Заблокировать'),
                                  onTap: () async {
                                    context.pop();
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                    try {
                                      await dataSource.toggleBlockInvestor(
                                        investor.id,
                                      );
                                      context.pop();
                                      context.read<InvestorsBloc>().add(
                                        LoadInvestorsEvent(refresh: true),
                                      );
                                    } catch (e) {
                                      context.pop();
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Ошибка'),
                                          content: Text(
                                            'Не удалось заблокировать инвестора.\n$e',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => context.pop(),
                                              child: const Text('Ок'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),

                                // Удалить
                                PopupMenuItem(
                                  child: const Text('Удалить'),
                                  onTap: () async {
                                    context.pop();
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Удаление инвестора'),
                                        content: const Text(
                                          'Вы уверены, что хотите удалить этого инвестора?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => context.pop(false),
                                            child: const Text('Отмена'),
                                          ),
                                          TextButton(
                                            onPressed: () => context.pop(true),
                                            child: const Text('Удалить'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                      try {
                                        await dataSource.deleteInvestor(
                                          investor.id,
                                        );
                                        context.pop();
                                        context.read<InvestorsBloc>().add(
                                          LoadInvestorsEvent(refresh: true),
                                        );
                                      } catch (e) {
                                        context.pop();
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Ошибка'),
                                            content: Text(
                                              'Не удалось удалить инвестора.\n$e',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => context.pop(),
                                                child: const Text('Ок'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ] else ...[
                                // Если заблокирован, показываем другие пункты
                                PopupMenuItem(
                                  child: const Text('Разблокировать'),
                                  onTap: () async {
                                    context.pop();
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                    try {
                                      await dataSource.toggleBlockInvestor(
                                        investor.id,
                                      );
                                      context.pop();
                                      context.read<InvestorsBloc>().add(
                                        LoadInvestorsEvent(refresh: true),
                                      );
                                    } catch (e) {
                                      context.pop();
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Ошибка'),
                                          content: Text(
                                            'Не удалось разблокировать инвестора.\n$e',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => context.pop(),
                                              child: const Text('Ок'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                                PopupMenuItem(
                                  child: const Text('Удалить'),
                                  onTap: () async {
                                    context.pop();
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Удаление инвестора'),
                                        content: const Text(
                                          'Вы уверены, что хотите удалить этого инвестора?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => context.pop(false),
                                            child: const Text('Отмена'),
                                          ),
                                          TextButton(
                                            onPressed: () => context.pop(true),
                                            child: const Text('Удалить'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                      try {
                                        await dataSource.deleteInvestor(
                                          investor.id,
                                        );
                                        context.pop();
                                        context.read<InvestorsBloc>().add(
                                          LoadInvestorsEvent(refresh: true),
                                        );
                                      } catch (e) {
                                        context.pop();
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Ошибка'),
                                            content: Text(
                                              'Не удалось удалить инвестора.\n$e',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => context.pop(),
                                                child: const Text('Ок'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                PopupMenuItem(
                                  child: const Text('Аннулировать'),
                                  onTap: () async {
                                    context.pop();
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Аннулирование'),
                                        content: const Text(
                                          'Вы уверены, что хотите аннулировать этого инвестора?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => context.pop(false),
                                            child: const Text('Отмена'),
                                          ),
                                          TextButton(
                                            onPressed: () => context.pop(true),
                                            child: const Text('Аннулировать'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );

                                      try {
                                        await dataSource.clearInvestor(
                                          investor.id,
                                        );
                                        context.pop();
                                        context.read<InvestorsBloc>().add(
                                          LoadInvestorsEvent(refresh: true),
                                        );
                                      } catch (e) {
                                        context.pop();
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Ошибка'),
                                            content: Text(
                                              'Не удалось аннулировать инвестора.\n$e',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => context.pop(),
                                                child: const Text('Ок'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ]
                          : null,

                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Никнейм: ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: detailedInvestor.nickname,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (canSeeNames) ...[
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'ФИО: ',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    TextSpan(
                                      text: detailedInvestor.fullName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Телефон: ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        detailedInvestor.phoneNumber ??
                                        "не указан",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Доля инвестора: ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${detailedInvestor.investorPie}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Инвестиция: ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${detailedInvestor.investmentAmount.toStringAsFixed(0)} ₽',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Касса: ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${detailedInvestor.balance.toStringAsFixed(0)} ₽',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            DefaultButton(
                              text: 'Закрыть',
                              color: Color(AppColors.primary),
                              onPressed: () => context.pop(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            } catch (e) {
              context.pop();
              showDialog(
                context: context,
                builder: (_) => AppModal(
                  title: 'Ошибка',
                  content: Text('Не удалось загрузить данные.\n$e'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Ок'),
                    ),
                  ],
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: investor.isBlocked
                  ? Colors.red.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      investor.nickname,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: investor.isBlocked ? Colors.red : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '${investor.balance.toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPositive
                          ? Color(AppColors.primaryLight)
                          : Color(AppColors.pinkTint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
