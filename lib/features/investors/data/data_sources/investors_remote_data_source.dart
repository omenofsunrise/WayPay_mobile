import 'package:waypay_mobile/features/investors/data/models/investor_payout_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_response.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_response_model.dart';

abstract class InvestorsRemoteDataSource {
  Future<InvestorsResponseModel> getInvestors({
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortDirection,
    String? search,
  });
  Future<InvestorsModel> getInvestorById(int id);
  Future<void> createInvestor({
    required String nickname,
    required String fullName,
    required String? phoneNumber,
    required int investorPie,
    required double investmentAmount,
  });
  Future<void> deleteInvestor(int id);
  Future<void> updateInvestor({
    required int id,
    required String nickname,
    required String fullName,
    String? phoneNumber,
    required int investorPie,
  });
  Future<void> addInvestment({required int id, required double amount});
  Future<void> toggleBlockInvestor(int id);
  Future<void> clearInvestor(int id);
  Future<Map<String, dynamic>> getInvestorReport(int id);
  Future<InvestorPayoutResponse> createInvestorPayout({
    required int investorId,
    required double amount,
  });
  Future<List<InvestorPayoutModel>> getInvestorPayoutsByInvestorId(
    int investorId,
  );
}
