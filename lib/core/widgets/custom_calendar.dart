import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomCalendar extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;

  const CustomCalendar({
    super.key,
    this.initialDate,
    required this.onDateSelected,
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

    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(
        displayedMonth.year,
        displayedMonth.month,
        day,
      );
      bool isToday =
          DateFormat('yyyy-MM-dd').format(currentDate) ==
          DateFormat('yyyy-MM-dd').format(DateTime.now());

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedDate = currentDate;
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: currentDate == selectedDate
                  ? Colors.blue
                  : isToday
                  ? Colors.blue.withOpacity(0.2)
                  : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color: currentDate == selectedDate
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ),
      );
    }

    return dayWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(icon: Icon(Icons.arrow_left), onPressed: _prevMonth),
                DropdownButton<String>(
                  value: months[displayedMonth.month - 1],
                  items: months.map((String month) {
                    return DropdownMenuItem<String>(
                      value: month,
                      child: Text(month),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    _setMonth(months.indexOf(value!));
                  },
                ),
                DropdownButton<int>(
                  value: displayedMonth.year,
                  items: List.generate(50, (index) => 2000 + index)
                      .map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text('$year'),
                        ),
                      )
                      .toList(),
                  onChanged: (int? value) {
                    _setYear(value!);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                  .map((day) => Expanded(child: Center(child: Text(day))))
                  .toList(),
            ),
            SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: _buildDays(),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Удалить'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedDate != null) {
                      widget.onDateSelected(selectedDate!);
                    }
                    Navigator.pop(context);
                  },
                  child: Text('Сегодня'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
