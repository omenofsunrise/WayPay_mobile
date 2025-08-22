import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/form_modal/labeled_container.dart';
import 'package:waypay/core/widgets/helpers.dart';
import 'package:waypay/features/clients/data/data_sources/blacklist/blacklist_remote_data_sources.dart';
import 'package:waypay/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay/features/clients/data/models/clients/client_model.dart';
import 'package:waypay/features/profile/data/models/employee.dart';

class BlacklistClientCard extends StatefulWidget {
  final ClientModel client;
  final VoidCallback? onDeleted;
  const BlacklistClientCard({super.key, required this.client, this.onDeleted});

  @override
  State<BlacklistClientCard> createState() => _BlacklistClientCardState();
}

class _BlacklistClientCardState extends State<BlacklistClientCard> {
  final userStorage = UserStorage();
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

  void _handleRemoveFromBlacklist(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      if (!context.mounted) return;
      Navigator.of(context).pop();

      final confirmed = await showConfirmDialog(
        context: context,
        title: 'Подтвердите удаление',
        content: 'Вы действительно хотите убрать клиента из ЧС?',
        confirmText: 'Удалить',
      );

      if (confirmed == true && context.mounted) {
        _deleteFromBlacklist(context);
      }
    });
  }

  void _showClientModal(BuildContext context, ClientModel client) {
    showDialog(
      context: context,
      builder: (_) => AppModal(
        title: 'Данные',
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledContainer(label: 'ID', text: client.id.toString()),
              LabeledContainer(label: 'ФИО', text: client.fullName),
              LabeledContainer(label: 'Дата рождения', text: _formatDate(client.birthdate)),
              LabeledContainer(label: 'Адрес регистрации', text: client.registrationAddress ?? '----'),
              LabeledContainer(label: 'Документ', text: client.doc),
              LabeledContainer(label: 'Телефон', text: client.phone),
              SizedBox(height: 16),
              if (userStorage.hasViewContent([EmployeeRole.superAdmin])) ...[
                DefaultButton(
                  text: 'Убрать из ЧС',
                  isGreen: true,
                  onPressed: () => _handleRemoveFromBlacklist(context),
                ),
                SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMMM yyyy', 'ru');
    return formatter.format(date);
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
          color: Colors.white,
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
