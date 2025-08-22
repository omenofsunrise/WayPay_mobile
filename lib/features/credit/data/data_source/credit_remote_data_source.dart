import 'package:waypay/features/credit/data/models/credit_model.dart';
import 'package:waypay/features/credit/data/models/credit_response_model.dart';
import 'package:waypay/features/credit/data/models/get_query_credits.dart';

abstract class CreditRemoteDataSource {
  Future<CreditResponseModel> getCredits(GetCreditsQuery query);
  Future<CreditModel> getCreditById(int id);
  Future<void> toggleFavourite(int creditId);
  Future<void> deleteCreditById(int id);
  Future<CreditResponseModel> getCreditsByInvestorId(int investorId, GetCreditsQuery query);
}
