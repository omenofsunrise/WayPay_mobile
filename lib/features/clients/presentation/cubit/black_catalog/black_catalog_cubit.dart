import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/black_catalog/black_catalog_remote_data_source.dart';
import 'package:waypay_mobile/features/clients/data/models/black_catalog/black_catalog_client_model.dart';
import 'package:waypay_mobile/features/clients/data/models/black_catalog/get_black_catalog_query.dart';

part 'black_catalog_state.dart';

class BlackCatalogCubit extends Cubit<BlackCatalogState> {
  BlackCatalogCubit({
    BlackCatalogRemoteDataSource? remoteDataSource,
  })  : _remoteDataSource =
            remoteDataSource ?? getIt<BlackCatalogRemoteDataSource>(),
        super(BlackCatalogInitial());

  final BlackCatalogRemoteDataSource _remoteDataSource;
  String _lastQuery = '';

  String get lastQuery => _lastQuery;

  Future<void> search(String query) async {
    _lastQuery = query;
    emit(BlackCatalogLoading());

    try {
      final response = await _remoteDataSource.getBlackCatalog(
        GetBlackCatalogQuery(
          fullName: _extractPhone(query) == null ? query : null,
          phone: _extractPhone(query),
          page: 1,
          pageSize: 30,
        ),
      );

      emit(BlackCatalogLoaded(response.items));
    } catch (e) {
      emit(BlackCatalogError('Ошибка загрузки чёрного каталога: $e'));
    }
  }

  String? _extractPhone(String? value) {
    if (value == null) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 11) {
      return digits;
    }
    return null;
  }
}
