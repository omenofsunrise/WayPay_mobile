import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/credit_application_model.dart';
import 'package:waypay_mobile/routes/routes.dart';

class ClientApplicationDetailScreen extends StatelessWidget {
  ClientApplicationDetailScreen({super.key, required this.application});

  final CreditApplicationModel application;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  String _formatCurrency(double? value) {
    if (value == null) return '—';
    return _currencyFormat.format(value);
  }

  String _formatTerm(int? months) {
    if (months == null || months <= 0) return '—';
    return '$months мес.';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return _dateFormat.format(date);
  }

  String _resolve(String? value) {
    if (value == null || value.trim().isEmpty) return '—';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final applicationNumber =
        application.applicationNumber ?? '№ ${application.id}';
    final managerName = _resolve(application.managerName);
    final clientName = _resolve(application.fullName);
    final region = _resolve(application.region);
    final district = _resolve(application.district);

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
                  title: 'Заявка $applicationNumber',
                  showBackButton: true,
                  showNotifications: false,
                ),
                const SizedBox(height: 16),
                _InfoCard(fields: [_InfoField('ФИО менеджера', managerName)]),
                const SizedBox(height: 12),
                _InfoCard(
                  fields: [
                    _InfoField('ФИО клиента', clientName),
                    _InfoField('Регион', region),
                    _InfoField('Район', district),
                  ],
                ),
                const SizedBox(height: 12),
                _ProductInfoCard(
                  title: _resolve(application.productName),
                  term: _formatTerm(application.termMonths),
                  firstPayment: _formatCurrency(application.firstPayment),
                  date: _formatDate(application.createdDate),
                  amount: _formatCurrency(
                    application.productPrice ?? application.totalAmount,
                  ),
                ),
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
                color: Color(AppColors.uiBorder),
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
  const _ProductInfoCard({
    required this.title,
    required this.term,
    required this.firstPayment,
    required this.date,
    required this.amount,
  });

  final String title;
  final String term;
  final String firstPayment;
  final String date;
  final String amount;

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
              color: Color(AppColors.uiBorder),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
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
                child: _ProductField(label: 'Срок', value: term),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _ProductField(
                  label: 'Первый взнос',
                  value: firstPayment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProductField(label: 'Дата', value: date),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _ProductField(label: 'Стоимость', value: amount),
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
