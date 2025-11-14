import 'package:waypay_mobile/features/sold_products/data/models/sold_product_model.dart';

abstract class SoldProductRemoteDataSource {
  Future<List<SoldProductModel>> fetchSoldProductsByCreditId(int creditId);
}
