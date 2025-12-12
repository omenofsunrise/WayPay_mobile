import 'package:waypay_mobile/features/bank_card/data/models/bank_card_model.dart';
import 'package:waypay_mobile/features/bank_card/data/models/bank_card_paged_result.dart';
import 'package:waypay_mobile/features/bank_card/data/models/bank_card_request.dart';

abstract class BankCardRemoteDataSource {
  Future<BankCardPagedResult> getBankCards({int page, int pageSize});
  Future<BankCardModel> createBankCard(BankCardRequest request);
  Future<BankCardModel> updateBankCard(int id, BankCardRequest request);
  Future<void> deleteBankCard(int id);
}
