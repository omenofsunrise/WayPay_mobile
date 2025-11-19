import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/expected/payment_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/get_payment_query.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';

part 'payment_history_state.dart';

class PaymentHistoryCubit extends Cubit<PaymentHistoryState> {
  PaymentHistoryCubit({PaymentRemoteDataSources? paymentRemoteDataSources})
    : _paymentRemoteDataSources =
            paymentRemoteDataSources ?? getIt<PaymentRemoteDataSources>(),
      super(PaymentHistoryInitial());

  final PaymentRemoteDataSources _paymentRemoteDataSources;

  Future<void> load({int limit = 2}) async {
    emit(PaymentHistoryLoading());
    try {
      final response = await _paymentRemoteDataSources.getPayment(
        GetPaymentsQuery(
          page: 1,
          pageSize: limit,
          sortBy: 'date',
          sortDirection: 'desc',
          confirmed: true,
        ),
      );
      emit(PaymentHistoryLoaded(response.items));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(
        PaymentHistoryError(
          'Ошибка получения истории платежей: $message',
        ),
      );
    }
  }
}
