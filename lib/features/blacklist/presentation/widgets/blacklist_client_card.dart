import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/form_modal/info_row.dart';
import 'package:waypay/features/blacklist/data/data_sources/blacklist_remote_data_sources.dart';
import 'package:waypay/features/clients/data/data_sources/clients_remote_data_source.dart';
import 'package:waypay/features/clients/data/models/client_model.dart';

class BlacklistClientCard extends StatefulWidget {
  final ClientModel client;
  final VoidCallback? onDeleted;
  const BlacklistClientCard({super.key, required this.client, this.onDeleted});

  @override
  State<BlacklistClientCard> createState() => _BlacklistClientCardState();
}

class _BlacklistClientCardState extends State<BlacklistClientCard> {
  Future<void> _loadClientAndShowModal(BuildContext context) async {
    final dataSource = getIt<ClientRemoteDataSource>();
    try {
      final fullClient = await dataSource.getClientById(widget.client.id);
      if (!context.mounted) return;
      _showClientModal(context, fullClient);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки клиента: $e')));
    }
  }

  void _showClientModal(BuildContext context, ClientModel client) {
    showDialog(
      context: context,
      builder: (_) => AppModal(
        title: 'Данные',
        menuItems: [
          PopupMenuItem(
            child: const Text('Убрать из ЧС'),
            onTap: () async {
              Navigator.of(context).pop();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Подтвердите удаление'),
                  content: const Text('Вы действительно хотите убрать клиента из ЧС?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Удалить')),
                  ],
                ),
              );
              if (confirmed == true) {
                if (!context.mounted) return;
                _deleteFromBlacklist(context);
              }
            },
          ),
        ],

        content: SingleChildScrollView(
          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(label: 'ID', value: client.id.toString()),
              InfoRow(label: 'ФИО', value: client.fullName),
              InfoRow(label: 'Дата рождения', value: _formatDate(client.birthdate)),
              InfoRow(label: 'Адрес регистрации', value: client.registrationAddress ?? '-'),
              InfoRow(label: 'Документ', value: client.doc),
              InfoRow(label: 'Телефон', value: client.phone),
              DefaultButton(text: 'Закрыть', color: Color(AppColors.primary), onPressed: () => context.pop()),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<void> _deleteFromBlacklist(BuildContext context) async {
    final dataSource = getIt<BlacklistRemoteDataSources>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await dataSource.fromBlackList(widget.client.id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Клиент успешно удалён')));
      if (widget.onDeleted != null) {
        widget.onDeleted!();
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления клиента: $e')));
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.client.fullName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(widget.client.phone, style: const TextStyle(fontSize: 14, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
