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
    bool keepCatalog = false,
    bool keepCategory = false,
  }) {
    return CreditCreationState(
      creditRequest: creditRequest ?? this.creditRequest,
      markupType: markupType ?? this.markupType,
      totalAmountWithSurcharge:
          totalAmountWithSurcharge ?? this.totalAmountWithSurcharge,
      selectedClient: selectedClient ?? this.selectedClient,
      selectedInvestor: selectedInvestor ?? this.selectedInvestor,
      selectedCatalog: keepCatalog ? this.selectedCatalog : (selectedCatalog),
      selectedCategory: keepCategory
          ? this.selectedCategory
          : (selectedCategory),
      schedulePreview: schedulePreview ?? this.schedulePreview,
      schedulePreviewLoading:
          schedulePreviewLoading ?? this.schedulePreviewLoading,
      schedulePreviewError: schedulePreviewError ?? this.schedulePreviewError,
    );
  }
}
