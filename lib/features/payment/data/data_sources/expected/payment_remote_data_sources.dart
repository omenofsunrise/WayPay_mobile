import 'package:waypay_mobile/features/payment/data/models/expected/get_payment_query.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';

abstract class PaymentRemoteDataSources {
  Future<PaymentListResponseModel> getPayment(GetPaymentsQuery query);
  Future<PaymentListResponseModel> getPaymentsByCredit({
    required int creditId,
    int page,
    int pageSize,
  });
  Future<PaymentItemModel> getPaymentById(int id);
  Future<void> createPayment({
    required int creditId,
    required double paymentAmount,
    required DateTime datePayment,
    required PaymentType type,
  });
  Future<void> confirmPayment(int id);
  Future<void> deletePayment(int id);
}
