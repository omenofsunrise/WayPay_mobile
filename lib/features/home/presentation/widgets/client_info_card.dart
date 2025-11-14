import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';

class ClientInfoCard extends StatelessWidget {
  const ClientInfoCard({
    super.key,
    required this.fullName,
    required this.clientId,
    required this.birthDate,
    required this.phone,
    required this.whatsApp,
    this.onTap,
  });

  final String fullName;
  final String clientId;
  final String birthDate;
  final String phone;
  final String whatsApp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x05000809),
            offset: Offset(0, 0),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ID: $clientId',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(AppColors.darkGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _LabeledValue(label: 'Дата рождения', value: birthDate),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _LabeledValue(label: 'Телефон', value: phone),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _LabeledValue(label: 'WhatsApp', value: whatsApp),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
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
        ),
      ],
    );
  }
}
