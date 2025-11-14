import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/features/analytics/presentation/widgets/dropdown.dart';

class PeriodAppBarAction extends StatelessWidget {
  final PeriodOption selected;
  final void Function(PeriodOption? option, DateTimeRange? range) onChanged;

  const PeriodAppBarAction({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      PeriodOption.thisMonth,
      ...PeriodOption.values.where((o) => o != PeriodOption.thisMonth),
    ];

    return PopupMenuButton<String>(
      tooltip: 'Выбрать период',
      icon: const Icon(Icons.date_range, color: Colors.white),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value == 'custom') {
          await _showCustomPeriodModal(context);
        } else {
          final opt = PeriodOption.values.firstWhere((e) => e.name == value);
          onChanged(opt, null);
        }
      },
      itemBuilder: (context) => [
        ...options.map(
          (opt) => PopupMenuItem<String>(
            value: opt.name,
            child: Row(
              children: [
                Icon(
                  opt == selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: opt == selected
                      ? const Color(AppColors.primary)
                      : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    opt.label,
                    style: AppStyle.manrope(
                      size: 14,
                      weight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'custom',
          child: Center(
            child: Text(
              'Другой период',
              style: AppStyle.manrope(
                size: 14,
                weight: FontWeight.w400,
                color: Color(AppColors.radioColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCustomPeriodModal(BuildContext context) async {
    DateTime? start;
    DateTime? end;

    String fmt(DateTime? d) {
      if (d == null) return 'Выбрать дату';
      const months = [
        'января',
        'февраля',
        'марта',
        'апреля',
        'мая',
        'июня',
        'июля',
        'августа',
        'сентября',
        'октября',
        'ноября',
        'декабря',
      ];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year} г. ';
    }

    Future<void> pick(bool isStart) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: isStart ? (start ?? now) : (end ?? now),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        if (isStart) {
          start = picked;
        } else {
          end = picked;
        }
      }
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(AppColors.background),
          child: SizedBox(
            height: 320,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 33),
                      Text(
                        'Выбор периода',
                        style: AppStyle.manrope(
                          size: 20,
                          weight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 33),
                    child: GestureDetector(
                      onTap: () async {
                        await pick(true);
                        setState(() {});
                      },
                      child: _dateField(label: 'с', value: fmt(start)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 33),
                    child: GestureDetector(
                      onTap: () async {
                        await pick(false);
                        setState(() {});
                      },
                      child: _dateField(label: 'по', value: fmt(end)),
                    ),
                  ),

                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 33),
                    child: Row(
                      children: [
                        Expanded(
                          child: DefaultButton(
                            text: 'Отменить',
                            isGreen: false,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: DefaultButton(
                            text: 'Выбрать',
                            color: const Color(AppColors.primary),
                            // ✅ всегда ненулевой колбэк, как в твоём рабочем примере
                            onPressed: (start != null && end != null)
                                ? () {
                                    Navigator.pop(ctx);
                                    onChanged(
                                      null,
                                      DateTimeRange(start: start!, end: end!),
                                    );
                                  }
                                : () {}, // пустая функция вместо null
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateField({required String label, required String value}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppStyle.manrope(
              size: 14,
              weight: FontWeight.w400,
              color: const Color(AppColors.grey),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: AppStyle.manrope(
                size: 14,
                weight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          const Icon(Icons.filter_alt, color: Color(AppColors.grey)),
        ],
      ),
    );
  }
}
