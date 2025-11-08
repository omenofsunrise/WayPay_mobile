import 'package:flutter/material.dart';

class CustomCalendar extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;
  final String prefix;

  const CustomCalendar({
    super.key,
    this.initialDate,
    required this.onDateSelected,
    this.prefix = 'Дата:',
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime displayedMonth;
  DateTime? selectedDate;

  final List<String> months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    displayedMonth = widget.initialDate ?? DateTime.now();
  }

  void _nextMonth() {
    setState(() {
      displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
    });
  }

  void _prevMonth() {
    setState(() {
      displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
    });
  }

  void _setMonth(int month) {
    setState(() {
      displayedMonth = DateTime(displayedMonth.year, month + 1);
    });
  }

  void _setYear(int year) {
    setState(() {
      displayedMonth = DateTime(year, displayedMonth.month);
    });
  }

  void _setToday() {
    setState(() {
      selectedDate = DateTime.now();
      displayedMonth = DateTime.now();
    });
  }

  void _clearDate() {
    setState(() {
      selectedDate = null;
    });
  }

  List<Widget> _buildDays() {
    final firstDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );
    final firstWeekday = (firstDayOfMonth.weekday + 6) % 7;
    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;

    List<Widget> dayWidgets = [];

    final prevMonthLastDay = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      0,
    ).day;
    for (int i = 0; i < firstWeekday; i++) {
      final day = prevMonthLastDay - firstWeekday + i + 1;
      final currentDate = DateTime(
        displayedMonth.year,
        displayedMonth.month - 1,
        day,
      );
      final isSelected =
          selectedDate != null &&
          currentDate.year == selectedDate!.year &&
          currentDate.month == selectedDate!.month &&
          currentDate.day == selectedDate!.day;

      dayWidgets.add(
        _buildDay(
          day: day,
          currentDate: currentDate,
          isSelected: isSelected,
          isOtherMonth: true,
        ),
      );
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(
        displayedMonth.year,
        displayedMonth.month,
        day,
      );
      final isSelected =
          selectedDate != null &&
          currentDate.year == selectedDate!.year &&
          currentDate.month == selectedDate!.month &&
          currentDate.day == selectedDate!.day;

      dayWidgets.add(
        _buildDay(
          day: day,
          currentDate: currentDate,
          isSelected: isSelected,
          isOtherMonth: false,
        ),
      );
    }

    final remainingDays = 35 - dayWidgets.length;
    for (int day = 1; day <= remainingDays; day++) {
      final currentDate = DateTime(
        displayedMonth.year,
        displayedMonth.month + 1,
        day,
      );
      final isSelected =
          selectedDate != null &&
          currentDate.year == selectedDate!.year &&
          currentDate.month == selectedDate!.month &&
          currentDate.day == selectedDate!.day;

      dayWidgets.add(
        _buildDay(
          day: day,
          currentDate: currentDate,
          isSelected: isSelected,
          isOtherMonth: true,
        ),
      );
    }

    return dayWidgets;
  }

  Widget _buildDay({
    required int day,
    required DateTime currentDate,
    required bool isSelected,
    required bool isOtherMonth,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDate = currentDate;
        });
        widget.onDateSelected(currentDate);
        Navigator.of(context).pop();
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE0E0) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          '$day',
          style: TextStyle(
            color: isOtherMonth ? const Color(0xFFADB3BC) : Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  List<int> _generateYears() {
    final currentYear = DateTime.now().year;
    return List.generate(21, (index) => currentYear - 10 + index);
  }

  @override
  Widget build(BuildContext context) {
    final years = _generateYears();

    if (!years.contains(displayedMonth.year)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          displayedMonth = DateTime(years.first, displayedMonth.month);
        });
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Colors.white,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: _prevMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                Row(
                  children: [
                    Container(
                      width: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: months[displayedMonth.month - 1],
                          items: months.map((String month) {
                            return DropdownMenuItem<String>(
                              value: month,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  month,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              _setMonth(months.indexOf(value));
                            }
                          },
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: Color(0xFF50555C),
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: years.contains(displayedMonth.year)
                              ? displayedMonth.year
                              : years.first,
                          items: years.map((int year) {
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '$year',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (int? value) {
                            if (value != null) {
                              _setYear(value);
                            }
                          },
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: Color(0xFF50555C),
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: _nextMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF50555C),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 8),

            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.0,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: _buildDays(),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _clearDate,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF007D88),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: const Text('Удалить', style: TextStyle(fontSize: 14)),
                ),
                TextButton(
                  onPressed: _setToday,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF007D88),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: const Text('Сегодня', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
