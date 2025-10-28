import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay/core/widgets/form_modal/labeled_container.dart';
import 'package:waypay/core/widgets/helpers.dart';
import 'package:waypay/features/clients/data/models/clients/client_model.dart';
import 'package:waypay/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay/features/clients/data/data_sources/queue/queue_remote_data_source.dart';
import 'package:waypay/features/clients/data/models/queue/queue_model.dart';
import 'package:waypay/features/clients/data/models/queue/queue_request_model.dart';

/// --- форматирование денег ---
final _moneyRu = NumberFormat.currency(
  locale: 'ru_RU',
  symbol: '₽',
  decimalDigits: 0,
);

String formatMoney(num? v) {
  if (v == null) return '';
  return _moneyRu.format(v).replaceAll('\u00A0', ' ');
}

class QueueCard extends StatefulWidget {
  final ClientModel client;
  final QueueItemModel queue;
  final VoidCallback? onQueueChanged;

  const QueueCard({
    super.key,
    required this.client,
    required this.queue,
    this.onQueueChanged,
  });

  @override
  State<QueueCard> createState() => _QueueCardState();
}

class _QueueCardState extends State<QueueCard> {
  final _clientDataSource = getIt<ClientRemoteDataSource>();
  final _queueDataSource = getIt<QueueRemoteDataSource>();

  Future<void> _handleCloseQueue(BuildContext context) async {
    try {
      await _queueDataSource.closeQueueById(widget.queue.id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      widget.onQueueChanged?.call();
      showMessage('Очередь успешно закрыта', context);
    } catch (e) {
      if (!context.mounted) return;
      showMessage('Ошибка при закрытии очереди: $e', context);
    }
  }

  Future<void> _handleDeleteQueue(BuildContext context) async {
    Navigator.of(context).pop();
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Подтвердите удаление',
      content: 'Вы действительно хотите удалить запись из очереди?',
    );

    if (confirmed) {
      try {
        await _queueDataSource.deleteQueueById(widget.queue.id);
        if (!context.mounted) return;
        widget.onQueueChanged?.call();
        showMessage('Запись из очереди удалена', context);
      } catch (e) {
        if (!context.mounted) return;
        showMessage('Ошибка удаления записи: $e', context);
      }
    }
  }

  Widget buildEditQueueModal({
    required BuildContext context,
    required QueueItemModel queue,
    required ClientModel client,
    required void Function(double sum, bool highPriority) onSave,
  }) {
    final amountController = TextEditingController();
    final clientController = TextEditingController(text: client.fullName);
    bool highPriority = queue.priority == 1;

    void formatAmount() {
      final oldText = amountController.text;
      final oldSelection = amountController.selection;
      final raw = oldText.replaceAll(RegExp(r'\D'), '');

      if (raw.isEmpty) {
        amountController.value = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
        return;
      }

      final parsed = int.tryParse(raw);
      if (parsed == null) return;

      final formatted = NumberFormat(
        "#,##0",
        "ru_RU",
      ).format(parsed).replaceAll(',', ' ');
      final newText = '$formatted ₽';

      int cursorPositionInRaw = 0;
      int digitCount = 0;

      for (int i = 0; i < oldSelection.baseOffset && i < oldText.length; i++) {
        if (RegExp(r'\d').hasMatch(oldText[i])) {
          digitCount++;
        }
      }
      cursorPositionInRaw = digitCount;

      int newCursorPosition = 0;
      int digitsPassed = 0;
      while (digitsPassed < cursorPositionInRaw &&
          newCursorPosition < newText.length) {
        if (RegExp(r'\d').hasMatch(newText[newCursorPosition])) {
          digitsPassed++;
        }
        newCursorPosition++;
      }
      if (newCursorPosition > newText.length) {
        newCursorPosition = newText.length;
      }

      amountController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }

    amountController.text =
        '${NumberFormat("#,##0", "ru_RU").format(queue.sum).replaceAll(',', ' ')} ₽';

    double getRawAmount() {
      final raw = amountController.text.replaceAll(RegExp(r'\D'), '');
      final value = double.tryParse(raw);
      return value != null && value > 0 ? value : 0;
    }

    return AppModal(
      title: 'Редактировать очередь',
      backgroundColor: Color(AppColors.background),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IgnorePointer(
                ignoring: true,
                child: LabeledTextField(
                  label: 'Клиент',
                  controller: clientController,
                  keyboardType: TextInputType.number,
                ),
              ),
              LabeledTextField(
                label: 'Сумма',
                controller: amountController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  formatAmount();
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Высокий приоритет',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Switch(
                    value: highPriority,
                    onChanged: (value) => setState(() {
                      highPriority = value;
                    }),
                    activeThumbColor: const Color(AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DefaultButton(
                      isGreen: false,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      text: 'Отмена',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DefaultButton(
                      isGreen: true,
                      onPressed: getRawAmount() > 0
                          ? () {
                              onSave(getRawAmount(), highPriority);
                              Navigator.of(context).pop();
                            }
                          : () {},
                      text: 'Сохранить',
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditQueueModal(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => buildEditQueueModal(
        context: context,
        queue: widget.queue,
        client: widget.client,
        onSave: (sum, highPriority) async {
          try {
            final updateRequest = QueueRequestModel(
              sum: sum,
              clientId: widget.client.id,
              priority: highPriority ? 1 : 0,
            );
            await _queueDataSource.updateQueueById(
              widget.queue.id,
              updateRequest,
            );
            widget.onQueueChanged?.call();
            if (context.mounted) {
              Navigator.of(context).pop();
              showMessage('Очередь успешно обновлена', context);
            }
          } catch (e) {
            if (context.mounted) {
              showMessage('Ошибка обновления очереди: $e', context);
            }
          }
        },
      ),
    );
  }

  Future<void> _loadClientAndShowModal(BuildContext context) async {
    try {
      final fullClient = await _clientDataSource.getClientById(
        widget.client.id,
      );
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AppModal(
          backgroundColor: Color(AppColors.background),
          menuItems: [
            PopupMenuItem(
              child: const Text('Удалить'),
              onTap: () => _handleDeleteQueue(context),
            ),
            PopupMenuItem(
              child: const Text('Редактировать'),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  _openEditQueueModal(context);
                });
              },
            ),
          ],
          title: 'О клиенте',
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledContainer(label: 'ФИО', text: fullClient.fullName),
                LabeledContainer(label: 'Телефон', text: fullClient.phone),
                LabeledContainer(
                  label: 'Сумма',
                  text: formatMoney(widget.queue.sum),
                ),
                LabeledContainer(
                  label: 'Приоритет',
                  text: widget.queue.priority == 0
                      ? 'Обычный приоритет'
                      : 'Высокий приоритет',
                ),
                const SizedBox(height: 22),
                DefaultButton(
                  text: 'Закрыть очередь',
                  onPressed: () => _handleCloseQueue(context),
                  color: Color(AppColors.primary),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      showMessage('Ошибка загрузки: $e', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _loadClientAndShowModal(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.queue.priority == 1
              ? const Color(AppColors.greenTint)
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
        child: Row(
          children: [
            Text(
              widget.queue.positionInQueue.toString(),
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.client.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.client.phone,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
