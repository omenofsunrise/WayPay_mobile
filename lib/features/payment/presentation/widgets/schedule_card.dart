import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waypay/assets/resources.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/form_modal/labeled_container.dart';
import 'package:waypay/features/payment/data/data_sources/schedule/schedule_remote_data_sources.dart';
import 'package:waypay/features/payment/data/models/schedule/schedule_model.dart';

class ScheduleCard extends StatefulWidget {
  final ScheduleModel schedule;

  const ScheduleCard({super.key, required this.schedule});

  @override
  State<ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  late ScheduleModel _schedule;
  @override
  void initState() {
    super.initState();
    _schedule = widget.schedule;
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    return formatter.format(amount);
  }

  void openWhatsApp(String phoneNumber) async {
    final dataSource = getIt<ScheduleRemoteDataSources>();
    final cleaned = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final formatted = cleaned.startsWith('8') ? '7${cleaned.substring(1)}' : cleaned;
    final message = Uri.encodeComponent(
      'Напоминание о платеже:\nСумма: ${_formatCurrency(_schedule.paymentAmount)}\nДата: ${_formatDate(_schedule.paymentDate)}',
    );
    final Uri url = Uri.parse('https://wa.me/$formatted?text=$message');
    try {
      bool launched = false;
      if (await canLaunchUrl(url)) {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
      await dataSource.putSchedule(widget.schedule.id);
      if (mounted) {
        setState(() {
          _schedule = _schedule.copyWith(notified: true);
        });
      }
    } catch (e) {
      log('Ошибка при открытии WhatsApp или обновлении уведомления: $e');
    }
  }

  void _showClientModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AppModal(
        backgroundColor: Color(AppColors.background),
        title: 'Информация',
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledContainer(label: 'Номер договора', text: _schedule.creditId.toString()),
              LabeledContainer(label: 'ФИО', text: _schedule.clientName),
              LabeledContainer(label: 'Платеж, руб', text: _formatCurrency(_schedule.paymentAmount)),
              LabeledContainer(label: 'Дата платежа', text: _formatDate(_schedule.paymentDate)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentDate = DateTime.tryParse(widget.schedule.paymentDate);
    final isOverdue = paymentDate != null && paymentDate.isBefore(DateTime.now());
    return InkWell(
      onTap: () => _showClientModal(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: !isOverdue ? Colors.white : Color(AppColors.pinkTint),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('№${widget.schedule.creditId}', style: const TextStyle(fontSize: 16, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(
                    widget.schedule.clientName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Платеж: ${_formatCurrency(widget.schedule.paymentAmount)}',
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => openWhatsApp(_schedule.clientPhone),
              child: _schedule.notified
                  ? const Icon(Icons.check_rounded, size: 30, color: Colors.black)
                  : Image.asset(Images.whatsappLogo, height: 60, width: 30),
            ),
          ],
        ),
      ),
    );
  }
}
