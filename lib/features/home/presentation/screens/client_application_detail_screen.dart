import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_applications_screen.dart';
import 'package:waypay_mobile/routes/routes.dart';

class ClientApplicationDetailScreen extends StatelessWidget {
  const ClientApplicationDetailScreen({super.key, required this.application});

  final ClientApplication application;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(
                  title: 'Заявка ${application.applicationNumber}',
                  showBackButton: true,
                  showNotifications: false,
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  fields: [
                    _InfoField('ФИО менеджера', application.managerName),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  fields: [
                    _InfoField('ФИО клиента', application.fullName),
                    _InfoField('Регион', application.region),
                    _InfoField('Район', application.district),
                  ],
                ),
                const SizedBox(height: 12),
                _ProductInfoCard(application: application),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: DefaultButton(
                        text: 'Написать',
                        showIcon: true,
                        iconWidget: SvgPicture.asset(
                          SvgIcons.chat2,
                          color: Colors.white,
                        ),
                        color: const Color(AppColors.primary),
                        textColor: Colors.white,
                        onPressed: () {
                          context.go(Routes.chatScreen.toPath);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DefaultButton(
                        text: 'Оформить',
                        showIcon: true,
                        iconWidget: SvgPicture.asset(
                          SvgIcons.add,
                          color: Colors.white,
                        ),

                        color: const Color(AppColors.primary),
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.fields});

  final List<_InfoField> fields;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i != 0) const SizedBox(height: 12),
            Text(
              fields[i].label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(AppColors.darkGrey),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fields[i].value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.black),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoField {
  const _InfoField(this.label, this.value);
  final String label;
  final String value;
}

class _ProductInfoCard extends StatelessWidget {
  const _ProductInfoCard({required this.application});

  final ClientApplication application;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Товар',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(AppColors.darkGrey),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            application.productName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.black),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProductField(label: 'Срок', value: application.term),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _ProductField(
                  label: 'Первый взнос',
                  value: application.firstPayment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProductField(
                  label: 'Дата',
                  value: application.issueDate,
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _ProductField(
                  label: 'Стоимость',
                  value: application.amount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductField extends StatelessWidget {
  const _ProductField({required this.label, required this.value});

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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF7A7E85),
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
