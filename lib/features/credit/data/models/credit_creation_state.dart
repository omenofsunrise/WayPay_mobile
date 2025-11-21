import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/schedule_preview_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';

class CreditCreationState {
  final CreateCreditRequest creditRequest;
  final int markupType;
  final double totalAmountWithSurcharge;
  final ClientModel? selectedClient;
  final InvestorsModel? selectedInvestor;
  final ObjectTypeModel? selectedCatalog;
  final ObjectTypeModel? selectedCategory;
  final List<SchedulePreviewModel> schedulePreview;
  final bool schedulePreviewLoading;
  final String? schedulePreviewError;
  final bool isSubmitting;
  final bool creditCreationSuccess;
  final String? submitError;

  CreditCreationState({
    required this.creditRequest,
    this.markupType = 0,
    required this.totalAmountWithSurcharge,
    this.selectedClient,
    this.selectedInvestor,
    this.selectedCatalog,
    this.selectedCategory,
    this.schedulePreview = const [],
    this.schedulePreviewLoading = false,
    this.schedulePreviewError,
    this.isSubmitting = false,
    this.creditCreationSuccess = false,
    this.submitError,
  });

  CreditCreationState copyWith({
    CreateCreditRequest? creditRequest,
    int? markupType,
    double? totalAmountWithSurcharge,
    ClientModel? selectedClient,
    InvestorsModel? selectedInvestor,
    ObjectTypeModel? selectedCatalog,
    ObjectTypeModel? selectedCategory,
    List<SchedulePreviewModel>? schedulePreview,
    bool? schedulePreviewLoading,
    String? schedulePreviewError,
    bool clearSelectedClient = false,
    bool clearSelectedInvestor = false,
    bool clearSelectedCatalog = false,
    bool clearSelectedCategory = false,
    bool clearSchedulePreviewError = false,
    bool? isSubmitting,
    bool? creditCreationSuccess,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return CreditCreationState(
      creditRequest: creditRequest ?? this.creditRequest,
      markupType: markupType ?? this.markupType,
      totalAmountWithSurcharge:
          totalAmountWithSurcharge ?? this.totalAmountWithSurcharge,
      selectedClient: clearSelectedClient
          ? null
          : (selectedClient ?? this.selectedClient),
      selectedInvestor: clearSelectedInvestor
          ? null
          : (selectedInvestor ?? this.selectedInvestor),
      selectedCatalog: clearSelectedCatalog
          ? null
          : (selectedCatalog ?? this.selectedCatalog),
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      schedulePreview: schedulePreview ?? this.schedulePreview,
      schedulePreviewLoading:
          schedulePreviewLoading ?? this.schedulePreviewLoading,
      schedulePreviewError: clearSchedulePreviewError
          ? null
          : (schedulePreviewError ?? this.schedulePreviewError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      creditCreationSuccess:
          creditCreationSuccess ?? this.creditCreationSuccess,
      submitError:
          clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}
