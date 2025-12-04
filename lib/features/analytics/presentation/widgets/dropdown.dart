import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';

enum PeriodOption {
  last7Days('За последние 7 дней'),
  thisMonth('За этот месяц'),
  last31Days('За последний 31 день'),
  previousMonth('За прошлый месяц'),
  thisYear('За этот год'),
  previousYear('За прошлый год');

  final String label;
  const PeriodOption(this.label);
}

class PeriodDropdown extends StatefulWidget {
  final void Function(PeriodOption? option, DateTimeRange? range)? onChanged;

  const PeriodDropdown({super.key, this.onChanged});

  @override
  State<PeriodDropdown> createState() => _PeriodDropdownState();
}

class _PeriodDropdownState extends State<PeriodDropdown> {
  PeriodOption? selectedOption;
  @override
  void initState() {
    super.initState();
    selectedOption = PeriodOption.thisMonth;
  }

  @override
  Widget build(BuildContext context) {
    final reorderedOptions = [
      PeriodOption.thisMonth,
      ...PeriodOption.values.where((e) => e != PeriodOption.thisMonth),
    ];
    return PopupMenuButton<String>(
      color: Colors.white,
      onSelected: (value) {
        if (value == 'custom') {
          _showCustomPeriodModal(context);
        } else {
          setState(() {
            selectedOption = PeriodOption.values.firstWhere(
              (e) => e.name == value,
            );
          });
          if (widget.onChanged != null) {
            widget.onChanged!(selectedOption, null);
          }
        }
      },
      itemBuilder: (context) => [
        ...reorderedOptions.map(
          (option) => PopupMenuItem<String>(
            value: option.name,
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              color: selectedOption == option
                  ? Color(AppColors.redTint)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _buildCustomRadio(option),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      option.label,
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w400,
                        color: selectedOption == option
                            ? Colors.black
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Color(AppColors.primary)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedOption?.label ?? 'Выбрать период',
              style: const TextStyle(fontSize: 14),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRadio(PeriodOption option) {
    final bool isSelected = selectedOption == option;
    if (!isSelected) {
      return SizedBox(
        width: 18,
        height: 18,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400, width: 2),
          ),
        ),
      );
    }

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Color(AppColors.radioColor), width: 1),
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(AppColors.radioColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomPeriodModal(BuildContext context) {
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;

    String formatDate(DateTime? date) {
      if (date == null) return 'Выбрать дату';
      final months = [
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
      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];
      final year = date.year;
      return '$day $month $year г. ';
    }

    Future<void> pickDate(BuildContext context, bool isStart) async {
      final initialDate = DateTime.now();
      final firstDate = DateTime(2000);
      final lastDate = DateTime(2100);
      final picked = await showDatePicker(
        context: context,
        initialDate: isStart
            ? (selectedStartDate ?? initialDate)
            : (selectedEndDate ?? initialDate),
        firstDate: firstDate,
        lastDate: lastDate,
      );
      if (picked != null) {
        if (isStart) {
          selectedStartDate = picked;
        } else {
          selectedEndDate = picked;
        }
      }
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Color(AppColors.background),
              child: SizedBox(
                height: 320,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 33),
                            child: Column(
                              children: [
                                SizedBox(height: 15),
                                Text(
                                  'Выбор периода',
                                  style: AppStyle.manrope(
                                    size: 20,
                                    weight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 33),
                        child: GestureDetector(
                          onTap: () async {
                            await pickDate(context, true);
                            setState(() {});
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'с',
                                  style: AppStyle.manrope(
                                    size: 14,
                                    weight: FontWeight.w400,
                                    color: Color(AppColors.grey),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    formatDate(selectedStartDate),
                                    style: AppStyle.manrope(
                                      size: 14,
                                      weight: FontWeight.w400,
                                      color: selectedStartDate == null
                                          ? Color(AppColors.grey)
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_month,
                                  color: Color(AppColors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 33),
                        child: GestureDetector(
                          onTap: () async {
                            await pickDate(context, false);
                            setState(() {});
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'по',
                                  style: AppStyle.manrope(
                                    size: 14,
                                    weight: FontWeight.w400,
                                    color: Color(AppColors.grey),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    formatDate(selectedEndDate),
                                    style: AppStyle.manrope(
                                      size: 14,
                                      weight: FontWeight.w400,
                                      color: selectedEndDate == null
                                          ? Color(AppColors.grey)
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_month,
                                  color: Color(AppColors.grey),
                                ),
                              ],
                            ),
                          ),
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
                                onPressed: () => Navigator.pop(context),
                                isPrimary: false,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: DefaultButton(
                                text: 'Выбрать',
                                onPressed:
                                    selectedStartDate != null &&
                                        selectedEndDate != null
                                    ? () {
                                        Navigator.pop(context);
                                        if (widget.onChanged != null &&
                                            selectedStartDate != null &&
                                            selectedEndDate != null) {
                                          widget.onChanged!(
                                            null,
                                            DateTimeRange(
                                              start: selectedStartDate!,
                                              end: selectedEndDate!,
                                            ),
                                          );
                                        }
                                      }
                                    : () {},
                                color: Color(AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
