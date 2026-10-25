import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/expected/payment_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/get_payment_query.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';
import 'package:waypay_mobile/features/payment/presentation/cubit/payment_history_cubit.dart';
import 'package:waypay_mobile/features/payment/presentation/widgets/payment_preview_card.dart';

class _FakePayments implements PaymentRemoteDataSources {
  GetPaymentsQuery? lastQuery;

  @override
  Future<PaymentListResponseModel> getPayment(GetPaymentsQuery query) async {
    lastQuery = query;
    return PaymentListResponseModel(
      totalPayments: 0,
      totalIncome: 0,
      page: 1,
      pageSize: 2,
      totalCount: 0,
      totalPages: 0,
      items: const [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PaymentItemModel _payment({required bool accepted}) => PaymentItemModel(
  id: 1,
  creditId: 42,
  paymentAmount: 1000,
  paymentDate: '2026-10-01T00:00:00',
  type: PaymentType.cash,
  accepted: accepted,
  clientFullName: 'Иванов Иван',
  income: 0,
);

Future<void> _pumpCard(WidgetTester tester, PaymentItemModel payment) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentPreviewCard(payment: payment, showStatus: true),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserStorage().clear();
  });

  group('UserStorage.saveCompanySettings', () {
    test('по умолчанию подтверждение включено', () async {
      expect(UserStorage().paymentAcceptance, isTrue);
      expect(await UserStorage().getPaymentAcceptance(), isTrue);
    });

    test('читает флаги из Auth/info', () async {
      await UserStorage().saveCompanySettings({
        'creditAcceptance': false,
        'paymentAcceptance': false,
      });
      expect(UserStorage().paymentAcceptance, isFalse);
      expect(UserStorage().creditAcceptanceNotifier.value, isFalse);
      expect(await UserStorage().getPaymentAcceptance(), isFalse);
    });

    test('флагов нет в ответе — считаем включёнными', () async {
      await UserStorage().saveCompanySettings({'paymentAcceptance': false});
      await UserStorage().saveCompanySettings({});
      expect(UserStorage().paymentAcceptance, isTrue);
    });
  });

  group('История на экране платежей', () {
    test('подтверждение включено — только подтверждённые', () async {
      final source = _FakePayments();
      await PaymentHistoryCubit(paymentRemoteDataSources: source).load();
      expect(source.lastQuery!.confirmed, isTrue);
    });

    test('подтверждение выключено — без фильтра по подтверждению', () async {
      await UserStorage().saveCompanySettings({'paymentAcceptance': false});
      final source = _FakePayments();
      await PaymentHistoryCubit(paymentRemoteDataSources: source).load();
      expect(source.lastQuery!.confirmed, isNull);
    });
  });

  group('Плашка на карточке платежа', () {
    testWidgets('подтверждённый платёж', (tester) async {
      await _pumpCard(tester, _payment(accepted: true));
      expect(find.text('Подтверждён'), findsOneWidget);
    });

    testWidgets('неподтверждённый платёж', (tester) async {
      await _pumpCard(tester, _payment(accepted: false));
      expect(find.text('Не подтверждён'), findsOneWidget);
      expect(find.text('Подтверждён'), findsNothing);
    });

    testWidgets('подтверждение выключено — плашки нет', (tester) async {
      await UserStorage().saveCompanySettings({'paymentAcceptance': false});
      await _pumpCard(tester, _payment(accepted: false));
      expect(find.text('Не подтверждён'), findsNothing);
      expect(find.text('Подтверждён'), findsNothing);
    });
  });
}
