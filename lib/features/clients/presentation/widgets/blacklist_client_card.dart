import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';

class BlacklistClientCard extends StatelessWidget {
  const BlacklistClientCard({
    super.key,
    required this.client,
  });

  final ClientModel client;

  String _formatDate(DateTime date) =>
      DateFormat('dd.MM.yyyy', 'ru').format(date);

  String _resolveWhatsapp() {
    final candidate = client.secondPhone?.trim();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
    return client.phone;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  client.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.black),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ID: ${client.id}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.darkGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoGroup(
            title: 'Дата рождения',
            value: _formatDate(client.birthdate),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoGroup(
                  title: 'Телефон',
                  value: client.phone,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoGroup(
                  title: 'WhatsApp',
                  value: _resolveWhatsapp(),
                  alignRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({
    required this.title,
    required this.value,
    this.alignRight = false,
  });

  final String title;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(AppColors.darkGrey),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.black),
          ),
          textAlign: alignRight ? TextAlign.end : TextAlign.start,
        ),
      ],
    );
  }
}
