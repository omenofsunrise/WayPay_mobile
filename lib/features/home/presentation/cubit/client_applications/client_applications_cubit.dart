import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/home/data/data_source/credit_application_remote_data_source.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/credit_application_model.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/create_credit_application_request.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/get_credit_applications_query.dart';
import 'package:waypay_mobile/features/home/domain/entities/client_application_filters.dart';

part 'client_applications_state.dart';

enum ClientApplicationsTab { all, mine }

class ClientApplicationsCubit extends Cubit<ClientApplicationsState> {
  ClientApplicationsCubit({
    CreditApplicationRemoteDataSource? remoteDataSource,
  })  : _remoteDataSource =
            remoteDataSource ?? getIt<CreditApplicationRemoteDataSource>(),
        super(ClientApplicationsState.initial());

  final CreditApplicationRemoteDataSource _remoteDataSource;

  static const _pageSize = 30;

  Future<void> loadApplications({
    required ClientApplicationsTab tab,
    required String query,
    ClientApplicationFilters? filters,
    bool replaceFilters = false,
  }) async {
    final normalizedFilters =
        replaceFilters ? filters : (filters ?? state.filters);

    emit(
      state.copyWith(
        allTab:
            tab == ClientApplicationsTab.all ? state.allTab.asLoading() : null,
        myTab:
            tab == ClientApplicationsTab.mine ? state.myTab.asLoading() : null,
        filters: normalizedFilters,
        clearFilters: replaceFilters && normalizedFilters == null,
        lastQuery: query,
      ),
    );

    try {
      final response = await _remoteDataSource.getCreditApplications(
        _buildQuery(
          tab: tab,
          query: query,
          filters: normalizedFilters,
        ),
      );

      final items = _applyLocalFilters(response.items, normalizedFilters);

      emit(
        state.copyWith(
          allTab: tab == ClientApplicationsTab.all
              ? state.allTab.asSuccess(items)
              : null,
          myTab: tab == ClientApplicationsTab.mine
              ? state.myTab.asSuccess(items)
              : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          allTab: tab == ClientApplicationsTab.all
              ? state.allTab.asError(e.toString())
              : null,
          myTab: tab == ClientApplicationsTab.mine
              ? state.myTab.asError(e.toString())
              : null,
        ),
      );
    }
  }

  Future<void> createApplication(
    CreateCreditApplicationRequest request,
  ) async {
    emit(
      state.copyWith(
        isCreating: true,
        creationSuccess: false,
        clearCreationError: true,
      ),
    );
    try {
      final created = await _remoteDataSource.createCreditApplication(request);

      emit(
        state.copyWith(
          isCreating: false,
          creationSuccess: true,
        ),
      );

      final tabToRefresh = created.isMine
          ? ClientApplicationsTab.mine
          : ClientApplicationsTab.all;

      await loadApplications(
        tab: tabToRefresh,
        query: state.lastQuery,
        filters: state.filters,
      );
    } catch (e) {
      emit(
        state.copyWith(
          isCreating: false,
          creationSuccess: false,
          creationError: e.toString(),
        ),
      );
    }
  }

  void clearCreationStatus() {
    emit(
      state.copyWith(
        creationSuccess: false,
        clearCreationError: true,
      ),
    );
  }

  GetCreditApplicationsQuery _buildQuery({
    required ClientApplicationsTab tab,
    required String query,
    ClientApplicationFilters? filters,
  }) {
    final normalizedQuery = query.trim();
    return GetCreditApplicationsQuery(
      page: 1,
      pageSize: _pageSize,
      search: normalizedQuery.isEmpty ? null : normalizedQuery,
      minPrice: filters?.minCost?.toDouble(),
      maxPrice: filters?.maxCost?.toDouble(),
      minTerm: filters?.minTerm,
      maxTerm: filters?.maxTerm,
      onlyMine: tab == ClientApplicationsTab.mine ? true : null,
    );
  }

  List<CreditApplicationModel> _applyLocalFilters(
    List<CreditApplicationModel> input,
    ClientApplicationFilters? filters,
  ) {
    if (filters == null || filters.isEmpty) {
      return input;
    }

    final filterRegion = filters.region?.trim().toLowerCase();
    final filterDistrict = filters.district?.trim().toLowerCase();

    return input.where((application) {
      final cost = application.productPrice ?? application.totalAmount;
      if (filters.minCost != null) {
        if (cost == null || cost < filters.minCost!) return false;
      }
      if (filters.maxCost != null) {
        if (cost == null || cost > filters.maxCost!) return false;
      }
      if (filters.minTerm != null) {
        final term = application.termMonths ?? 0;
        if (term < filters.minTerm!) return false;
      }
      if (filters.maxTerm != null) {
        final term = application.termMonths ?? 0;
        if (term > filters.maxTerm!) return false;
      }
      if (filterRegion != null && filterRegion.isNotEmpty) {
        final region = (application.region ?? '').trim().toLowerCase();
        if (region.isEmpty || !region.contains(filterRegion)) return false;
      }
      if (filterDistrict != null && filterDistrict.isNotEmpty) {
        final district = (application.district ?? '').trim().toLowerCase();
        if (district.isEmpty || !district.contains(filterDistrict)) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
