import 'package:waypay_mobile/features/clients/data/models/black_catalog/get_black_catalog_query.dart';
import 'package:waypay_mobile/features/clients/data/models/black_catalog/paged_black_catalog_result.dart';

abstract class BlackCatalogRemoteDataSource {
  Future<PagedBlackCatalogResult> getBlackCatalog(
    GetBlackCatalogQuery query,
  );
}
