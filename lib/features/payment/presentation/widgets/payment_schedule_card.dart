import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/features/payment/data/models/payment_schedule_summary.dart';

class PaymentScheduleCard extends StatelessWidget {
  const PaymentScheduleCard({super.key, required this.summary});

  final PaymentScheduleSummary summary;

  double get _paidPercent =>
      summary.incomePercent == 0 && summary.expectedIncome > 0
          ? (summary.realIncome / summary.expectedIncome) * 100
          : summary.incomePercent;

  double get _debtPercent =>
      summary.debtPercent == 0 && summary.expectedIncome > 0
          ? (summary.debt / summary.expectedIncome) * 100
          : summary.debtPercent;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            summary.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.black),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DonutChart(
                paidPercent: _paidPercent.clamp(0, 100),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PercentRow(
                      color: const Color(AppColors.primary),
                      label: 'Оплачено',
                      value: _paidPercent,
                    ),
                    const SizedBox(height: 12),
                    _PercentRow(
                      color: const Color(AppColors.red),
                      label: 'Осталось',
                      value: _debtPercent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AmountRow(
            label: 'Ожидаемые платежи',
            value: formatter.format(summary.expectedIncome),
            valueColor: const Color(AppColors.black),
          ),
          const SizedBox(height: 8),
          _AmountRow(
            label: 'Оплатили',
            value: formatter.format(summary.realIncome),
            valueColor: const Color(AppColors.primary),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _AmountRow(
            label: 'Остаток',
            value: formatter.format(summary.debt),
            valueColor: const Color(AppColors.red),
          ),
        ],
      ),
    );
  }
}

class _PercentRow extends StatelessWidget {
  const _PercentRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(AppColors.darkGrey),
            ),
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(AppColors.darkGrey),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.paidPercent});

  final double paidPercent;

  @override
  Widget build(BuildContext context) {
    final value = (paidPercent / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(AppColors.red),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            height: 120,
            child: Transform.rotate(
              angle: -math.pi / 2,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(AppColors.primary),
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          Text(
            '${paidPercent.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
