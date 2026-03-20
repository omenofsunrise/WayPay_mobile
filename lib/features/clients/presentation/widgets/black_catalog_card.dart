import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/features/clients/data/models/black_catalog/black_catalog_client_model.dart';
import 'package:waypay_styles/waypay_styles.dart';

class BlackCatalogCard extends StatelessWidget {
  const BlackCatalogCard({super.key, required this.client});

  final BlackCatalogClientModel client;

  static const _shadow = [
    BoxShadow(color: Color(0x14000809), offset: Offset(2, 2), blurRadius: 4),
    BoxShadow(color: Color(0x05000809), offset: Offset(0, 0), blurRadius: 6),
  ];

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _resolveDoc() {
    final value = client.doc;
    if (value == null || value.isEmpty) return '—';
    return value;
  }

  String _resolveAddress() {
    final value = client.address;
    if (value == null || value.isEmpty) return '—';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    client.fullName ?? '—',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'ID: ${client.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _LabeledValue(label: 'Документ', value: _resolveDoc()),
            const SizedBox(height: 20),
            _LabeledValue(
              label: 'Дата рождения',
              value: _formatDate(client.birthdate),
            ),
            const SizedBox(height: 20),
            _LabeledValue(label: 'Адрес', value: _resolveAddress()),
          ],
        ),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(AppColors.uiBorder),
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
        ),
      ],
    );
  }
}
