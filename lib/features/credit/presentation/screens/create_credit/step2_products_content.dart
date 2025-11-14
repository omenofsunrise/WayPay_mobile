import 'package:flutter/material.dart';

class Step2ProductsContent extends StatelessWidget {
  const Step2ProductsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выбор продукта',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Здесь будет контент для выбора продукта...'),
            // Добавьте реальный контент для выбора продуктов
            _buildProductItem(
              'Базовый кредит',
              '10% годовых',
              Icons.credit_card,
            ),
            _buildProductItem('Премиум кредит', '8% годовых', Icons.diamond),
            _buildProductItem('Экспресс кредит', '12% годовых', Icons.flash_on),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, size: 40),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        // Обработка выбора продукта
      },
    );
  }
}
