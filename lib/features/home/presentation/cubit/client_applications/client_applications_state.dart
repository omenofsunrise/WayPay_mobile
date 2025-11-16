part of 'client_applications_cubit.dart';

class ClientApplicationsTabData {
  const ClientApplicationsTabData({
    required this.items,
    required this.isLoading,
    required this.initialized,
    this.error,
  });

  final List<CreditApplicationModel> items;
  final bool isLoading;
  final bool initialized;
  final String? error;

  factory ClientApplicationsTabData.initial() => const ClientApplicationsTabData(
        items: [],
        isLoading: false,
        initialized: false,
        error: null,
      );

  ClientApplicationsTabData copyWith({
    List<CreditApplicationModel>? items,
    bool? isLoading,
    bool? initialized,
    String? error,
    bool clearError = false,
  }) {
    return ClientApplicationsTabData(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      initialized: initialized ?? this.initialized,
      error: clearError ? null : (error ?? this.error),
    );
  }

  ClientApplicationsTabData asLoading() => copyWith(
        isLoading: true,
        clearError: true,
        initialized: true,
      );

  ClientApplicationsTabData asSuccess(
    List<CreditApplicationModel> items,
  ) =>
      copyWith(
        items: items,
        isLoading: false,
        initialized: true,
        clearError: true,
      );

  ClientApplicationsTabData asError(String message) => copyWith(
        isLoading: false,
        initialized: true,
        error: message,
      );
}

class ClientApplicationsState {
  const ClientApplicationsState({
    required this.allTab,
    required this.myTab,
    this.filters,
    this.lastQuery = '',
    this.isCreating = false,
    this.creationSuccess = false,
    this.creationError,
  });

  final ClientApplicationsTabData allTab;
  final ClientApplicationsTabData myTab;
  final ClientApplicationFilters? filters;
  final String lastQuery;
  final bool isCreating;
  final bool creationSuccess;
  final String? creationError;

  factory ClientApplicationsState.initial() => ClientApplicationsState(
        allTab: ClientApplicationsTabData.initial(),
        myTab: ClientApplicationsTabData.initial(),
      );

  ClientApplicationsState copyWith({
    ClientApplicationsTabData? allTab,
    ClientApplicationsTabData? myTab,
    ClientApplicationFilters? filters,
    bool clearFilters = false,
    String? lastQuery,
    bool? isCreating,
    bool? creationSuccess,
    String? creationError,
    bool clearCreationError = false,
  }) {
    return ClientApplicationsState(
      allTab: allTab ?? this.allTab,
      myTab: myTab ?? this.myTab,
      filters: clearFilters ? null : (filters ?? this.filters),
      lastQuery: lastQuery ?? this.lastQuery,
      isCreating: isCreating ?? this.isCreating,
      creationSuccess: creationSuccess ?? this.creationSuccess,
      creationError: clearCreationError
          ? null
          : (creationError ?? this.creationError),
    );
  }
}
