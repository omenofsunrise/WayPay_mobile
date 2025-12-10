import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/form_modal/labeled_container.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/core/widgets/app_modal.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/expected/payment_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';
import 'package:waypay_mobile/features/payment/presentation/bloc/expected/payment_bloc.dart';

class PaymentCard extends StatefulWidget {
  final PaymentItemModel payment;

  const PaymentCard({super.key, required this.payment});

  @override
  State<PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<PaymentCard> {
  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  void _showClientModal(BuildContext context, PaymentItemModel payment) {
    showDialog(
      context: context,
      builder: (_) {
        final UserStorage userStorage = UserStorage();
        final canManageAccounting = userStorage.hasPermissionSync(
          const [Permission.manageAccounting],
        );
        return AppModal(
          backgroundColor: Color(AppColors.background),
          menuItems: [
            if (canManageAccounting && !payment.accepted)
              PopupMenuItem(
                child: const Text('Подтвердить'),
                onTap: () {
                  Future.delayed(Duration.zero, () async {
                    if (!context.mounted) return;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Color(AppColors.background),
                        title: const Text('Подтверждение'),
                        content: const Text(
                          'Вы уверены, что хотите подтвердить этот платёж?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Подтвердить'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      context.read<PaymentBloc>().add(
                        ConfirmPayment(payment.id),
                      );
                      Navigator.of(context).pop();
                    }
                  });
                },
              ),
            if (!payment.accepted)
              PopupMenuItem(
                child: const Text('Удалить'),
                onTap: () {
                  Future.delayed(Duration.zero, () async {
                    if (!context.mounted) return;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Color(AppColors.background),
                        title: const Text('Подтверждение удаления'),
                        content: const Text(
                          'Вы действительно хотите удалить этот платёж? Это действие необратимо.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      context.read<PaymentBloc>().add(
                        DeletePayment(payment.id),
                      );
                      Navigator.of(context).pop();
                    }
                  });
                },
              ),
          ],
          title: 'Информация',
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledContainer(
                  label: 'Договор №',
                  text: payment.creditId.toString(),
                ),
                LabeledContainer(label: 'ФИО', text: payment.clientFullName),
                LabeledContainer(
                  label: 'Платеж',
                  text: _formatCurrency(payment.paymentAmount),
                ),
                LabeledContainer(
                  label: 'Дата платежа',
                  text: _formatDate(payment.paymentDate),
                ),
                LabeledContainer(
                  label: 'Тип платежа',
                  text: payment.type == PaymentType.card
                      ? 'Картой'
                      : 'Наличкой',
                ),
                LabeledContainer(
                  label: 'Платеж принял',
                  text: payment.employeeFullName ?? '-',
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('d MMMM yyyy', 'ru_RU').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _loadPaymentAndShowModal(BuildContext context) async {
    final dataSource = getIt<PaymentRemoteDataSources>();
    try {
      final payment = await dataSource.getPaymentById(widget.payment.id);
      if (!context.mounted) return;
      _showClientModal(context, payment);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _loadPaymentAndShowModal(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.payment.accepted
              ? Color(AppColors.greenTint)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              '№${widget.payment.creditId.toString()}',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(width: 24),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.payment.clientFullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Платеж: ${_formatCurrency(widget.payment.paymentAmount)}',
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
