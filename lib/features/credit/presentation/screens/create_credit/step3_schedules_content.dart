import 'package:flutter/material.dart';

class Step3SchedulesContent extends StatelessWidget {
  const Step3SchedulesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'График платежей',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Здесь будет контент для графика платежей...'),
            // Добавьте реальный контент для графика платежей
            _buildScheduleItem('Январь 2024', '15 000 ₸', '15.01.2024'),
            _buildScheduleItem('Февраль 2024', '15 000 ₸', '15.02.2024'),
            _buildScheduleItem('Март 2024', '15 000 ₸', '15.03.2024'),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(String period, String amount, String date) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.calendar_today, size: 20),
      ),
      title: Text(period, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(date),
      trailing: Text(
        amount,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
