import 'package:flutter/material.dart';
import 'package:waypay/features/sold_products/data/data_sources/sold_product_remote_data_source.dart';
import 'package:waypay/features/sold_products/data/models/sold_product_model.dart';

class SoldProductCard extends StatelessWidget {
  final SoldProductModel soldProduct;

  const SoldProductCard({Key? key, required this.soldProduct})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              soldProduct.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Цена:'),
                Text('${soldProduct.price.toStringAsFixed(2)} ₽'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Наценка:'),
                Text('${soldProduct.surcharge.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Сумма наценки:'),
                Text('${soldProduct.surchargeAmount.toStringAsFixed(2)} ₽'),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Итого:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${soldProduct.totalAmount.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Виджет списка проданных товаров
class SoldProductsList extends StatelessWidget {
  final List<SoldProductModel> soldProducts;

  const SoldProductsList({Key? key, required this.soldProducts})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (soldProducts.isEmpty) {
      return const Center(child: Text('Нет проданных товаров'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: soldProducts.length,
      itemBuilder: (context, index) {
        return SoldProductCard(soldProduct: soldProducts[index]);
      },
    );
  }
}

// Пример использования в UI
class SoldProductsSection extends StatefulWidget {
  final int creditId;
  final SoldProductRemoteDataSource dataSource;

  const SoldProductsSection({
    Key? key,
    required this.creditId,
    required this.dataSource,
  }) : super(key: key);

  @override
  State<SoldProductsSection> createState() => _SoldProductsSectionState();
}

class _SoldProductsSectionState extends State<SoldProductsSection> {
  late Future<List<SoldProductModel>> _soldProductsFuture;

  @override
  void initState() {
    super.initState();
    _soldProductsFuture = widget.dataSource.fetchSoldProductsByCreditId(
      widget.creditId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SoldProductModel>>(
      future: _soldProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final soldProducts = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Проданные товары',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SoldProductsList(soldProducts: soldProducts),
          ],
        );
      },
    );
  }
}
