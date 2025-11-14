import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_calendar.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_input.dart';
import 'package:waypay_mobile/core/widgets/inputs/date_input.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';
import 'package:waypay_mobile/features/credit/presentation/cubit/credit_creation_provider.dart';

class Step1DetailsContent extends StatefulWidget {
  final TextEditingController firstPaymentController;
  final TextEditingController termMonthsController;
  final TextEditingController paymentDayController;

  const Step1DetailsContent({
    super.key,
    required this.firstPaymentController,
    required this.termMonthsController,
    required this.paymentDayController,
  });

  @override
  State<Step1DetailsContent> createState() => _Step1DetailsContentState();
}

class _Step1DetailsContentState extends State<Step1DetailsContent> {
  final _creditNameController = TextEditingController();
  final _debtCommentController = TextEditingController();
  final _creditDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFromState();
  }

  void _initializeFromState() {
    final state = context.read<CreditCreationCubit>().state;

    // Инициализируем контроллеры из состояния
    if (state.name.isNotEmpty) {
      _creditNameController.text = state.name;
    }

    if (state.debtComment != null && state.debtComment!.isNotEmpty) {
      _debtCommentController.text = state.debtComment!;
    }

    if (state.creditDate != null) {
      _updateDateController(state.creditDate!);
    }
  }

  void _updateDateController(DateTime date) {
    final formattedDate =
        '${_formatTwoDigits(date.day)}.${_formatTwoDigits(date.month)}.${date.year}';
    _creditDateController.text = formattedDate;
  }

  String _formatTwoDigits(int number) {
    return number.toString().padLeft(2, '0');
  }

  void _showCalendar() {
    final currentState = context.read<CreditCreationCubit>().state;
    final initialDate = currentState.creditDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => CustomCalendar(
        initialDate: initialDate,
        onDateSelected: (DateTime date) {
          _updateDateController(date);
          context.read<CreditCreationCubit>().updateBasicInfo(creditDate: date);
        },
        prefix: 'Дата:',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Основная информация',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Чекбокс "Договор в долг"
                BlocBuilder<CreditCreationCubit, CreateCreditRequest>(
                  builder: (context, state) {
                    return SwitchListTile(
                      title: const Text('Договор в долг'),
                      value: state.inDebt,
                      onChanged: (value) {
                        context.read<CreditCreationCubit>().updatePaymentInfo(
                          inDebt: value,
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 12),

                // DateInput для выбора даты
                DateInput(
                  controller: _creditDateController,
                  label: 'Выберите дату',
                  initialDate: context
                      .read<CreditCreationCubit>()
                      .state
                      .creditDate,
                  onDateSelected: (date) {
                    context.read<CreditCreationCubit>().updateBasicInfo(
                      creditDate: date,
                    );
                  },
                ),

                const SizedBox(height: 12),

                // CustomInput для названия договора
                CustomInput(
                  controller: _creditNameController,
                  label: 'Название договора (необязательно)',
                  onChanged: (value) {
                    context.read<CreditCreationCubit>().updateBasicInfo(
                      name: value.isEmpty ? null : value,
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Условное отображение: комментарий или поле для инвестора
                BlocBuilder<CreditCreationCubit, CreateCreditRequest>(
                  builder: (context, state) {
                    if (state.inDebt) {
                      // Если договор в долг - показываем комментарий
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Комментарий к долгу',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _debtCommentController,
                            decoration: const InputDecoration(
                              hintText: 'Введите комментарий...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onChanged: (value) {
                              context
                                  .read<CreditCreationCubit>()
                                  .updatePaymentInfo(
                                    debtComment: value.isEmpty ? null : value,
                                  );
                            },
                          ),
                        ],
                      );
                    } else {
                      // Если не в долг - показываем поле для инвестора
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Инвестор',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Здесь можно добавить CustomSelect для выбора инвестора
                          // Пока оставим placeholder
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Color(AppColors.lightGreyBackground),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Выберите инвестора',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Остальные поля (первый платеж, срок, день платежа)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Параметры платежей',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: widget.firstPaymentController,
                  decoration: const InputDecoration(
                    labelText: 'Первый платеж',
                    border: OutlineInputBorder(),
                    suffixText: '₸',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Введите сумму';
                    final amount = double.tryParse(value!);
                    if (amount == null || amount <= 0) {
                      return 'Введите корректную сумму';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      context.read<CreditCreationCubit>().updatePaymentInfo(
                        firstPayment: double.tryParse(value),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: widget.termMonthsController,
                  decoration: const InputDecoration(
                    labelText: 'Срок кредита (месяцев)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Введите срок';
                    final months = int.tryParse(value!);
                    if (months == null || months <= 0) {
                      return 'Введите корректный срок';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      context.read<CreditCreationCubit>().updatePaymentInfo(
                        termMonths: int.tryParse(value),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: widget.paymentDayController,
                  decoration: const InputDecoration(
                    labelText: 'День платежа (число месяца)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Введите день';
                    final day = int.tryParse(value!);
                    if (day == null || day < 1 || day > 31) {
                      return 'Введите число от 1 до 31';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      context.read<CreditCreationCubit>().updatePaymentInfo(
                        paymentDay: int.tryParse(value),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _creditNameController.dispose();
    _debtCommentController.dispose();
    _creditDateController.dispose();
    super.dispose();
  }
}
