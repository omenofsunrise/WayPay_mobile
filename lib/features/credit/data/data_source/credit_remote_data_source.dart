import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_response_model.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/schedule_preview_model.dart';

abstract class CreditRemoteDataSource {
  Future<CreditResponseModel> getCredits(GetCreditsQuery query);
  Future<CreditModel> getCreditById(int id);
  Future<void> toggleFavourite(int creditId);
  Future<void> deleteCreditById(int id);
  Future createCredit(CreateCreditRequest request);
  Future<CreditResponseModel> getCreditsByInvestorId(
    int investorId,
    GetCreditsQuery query,
  );
  Future<void> createCredit(CreateCreditRequest request);
  Future<List<SchedulePreviewModel>> getSchedulePreview({
    required double totalAmount,
    required double firstPayment,
    required int termMonths,
    required int paymentDay,
    required bool currentMonthStart,
    required bool nextMonthStart,
  });
}
