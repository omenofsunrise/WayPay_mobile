import 'package:waypay_mobile/features/investors/data/models/investor_cash_position_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_contribution_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';
import 'package:waypay_mobile/features/investors/data/models/move_cash_position_request.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_response.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_response_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_response_model.dart';
import 'package:waypay_mobile/features/investors/data/models/reinvestment_model.dart';

abstract class InvestorsRemoteDataSource {
  Future<InvestorsResponseModel> getInvestors({
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortDirection,
    String? search,
    int? poolId,
  });
  Future<InvestorPoolResponseModel> getInvestorPools({
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
    required DateTime activeUntil,
    int? poolId,
  });
  Future<void> deleteInvestor(int id);
  Future<void> updateInvestor({
    required int id,
    required String nickname,
    required String fullName,
    String? phoneNumber,
    required int investorPie,
    required DateTime activeUntil,
  });
  Future<void> addInvestment({
    required int id,
    required double amount,
    DateTime? date,
  });
  Future<void> toggleBlockInvestor(int id);
  Future<void> clearInvestor(int id);
  Future<Map<String, dynamic>> getInvestorReport(int id);
  Future<Map<String, dynamic>> getInvestorAgreement(int id);
  Future<Map<String, dynamic>> getDeletedInvestorInfo();
  Future<Map<String, dynamic>> createInvestorShareLink(
    int investorId, {
    int? minutes,
  });
  Future<Map<String, dynamic>> getInvestorPoolReport(int id);
  Future<InvestorPayoutResponse> createInvestorPayout({
    required int investorId,
    required double amount,
    String? payoutSource,
  });
  Future<List<InvestorPayoutModel>> getInvestorPayoutsByInvestorId(
    int investorId,
  );
  Future<List<InvestorPayoutModel>> getInvestorPayoutsByPoolId(int poolId);
  Future<void> deleteInvestorPayout(int id);
  Future<InvestorContributionsPage> getInvestorContributions({
    int? investorId,
    int? poolId,
    int page,
    int pageSize,
  });
  Future<void> updateInvestmentContribution({
    required int id,
    required double amount,
    required DateTime date,
  });
  Future<void> makeInvestmentContributionAction(int id, String action);
  Future<InvestorPoolModel> createInvestorPool(String name);
  Future<void> updateInvestorPoolName(int id, String name);
  Future<void> deleteInvestorPool(int id);
  Future<void> reinvestInvestorPool(int id);
  Future<List<ReinvestmentModel>> getReinvestments(
    int poolId, {
    int page,
    int pageSize,
    int? investorId,
  });

  /// История переводов кассы инвестора (отдельная касса / пул).
  Future<InvestorCashPositionHistoryResponse> getCashPositionHistory(
    int investorId, {
    int page,
  });

  /// Перевести кассу инвестора в пул или в отдельную кассу.
  Future<void> moveCashPosition(MoveCashPositionRequest request);

  /// Удалить запись из истории переводов кассы.
  Future<void> deleteCashPosition(int id);
}
