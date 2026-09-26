import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/notification_socket.dart';
import 'package:get_it/get_it.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/admin_panel/data/data_sources/company_remote_data_source.dart';
import 'package:waypay_mobile/features/admin_panel/data/data_sources/company_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/admin_panel/presentation/cubit/company_cubit.dart';
import 'package:waypay_mobile/features/analytics/data/data_sources/analytic_remote_data_source.dart';
import 'package:waypay_mobile/features/analytics/data/data_sources/analytic_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/debt_dynamic_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/investment_dynamic_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/sell_info_cubit.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:waypay_mobile/features/bank_card/data/data_sources/bank_card_remote_data_source.dart';
import 'package:waypay_mobile/features/bank_card/data/data_sources/bank_card_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/blacklist/blacklist_remote_data_sources.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/blacklist/blacklist_remote_data_sources_impl.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/blacklist/blacklist_bloc.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/clients/clients_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/objectType/data/data_source/object_type_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_bloc.dart';
import 'package:waypay_mobile/features/finance/data/data_source/budget_remote_data_source.dart';
import 'package:waypay_mobile/features/finance/data/data_source/budget_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_expense_bloc.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_income_bloc.dart';
import 'package:waypay_mobile/features/home/data/data_source/credit_application_remote_data_source.dart';
import 'package:waypay_mobile/features/home/data/data_source/credit_application_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/home/presentation/cubit/client_applications/client_applications_cubit.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay_mobile/features/note/data/data_sources/note_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/notifications/data/data_source/notifications_data_source.dart';
import 'package:waypay_mobile/features/notifications/data/data_source/notifications_data_source_impl.dart';
import 'package:waypay_mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/queue/queue_remote_data_source.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/queue/queue_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/queue/queue_bloc.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/schedule/schedule_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/schedule/schedule_remote_data_sources_impl.dart';
import 'package:waypay_mobile/features/payment/presentation/bloc/schedule/schedule_bloc.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/expected/payment_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/expected/payment_remote_data_sources_impl.dart';
import 'package:waypay_mobile/features/payment/presentation/bloc/expected/payment_bloc.dart';
import 'package:waypay_mobile/features/payment/presentation/cubit/payment_schedule_cubit.dart';
import 'package:waypay_mobile/features/payment/presentation/cubit/payment_history_cubit.dart';
import 'package:waypay_mobile/features/payment/presentation/cubit/schedule_preview_cubit.dart';
import 'package:waypay_mobile/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:waypay_mobile/features/profile/data/data_sources/employee_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:waypay_mobile/features/profile/presentation/cubit/credit_stats_cubit.dart';
import 'package:waypay_mobile/features/profile/presentation/cubit/payment_stats_cubit.dart';
import 'package:waypay_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:waypay_mobile/features/sold_products/data/data_sources/sold_product_remote_data_source.dart';
import 'package:waypay_mobile/features/sold_products/data/data_sources/sold_product_remote_data_source_impl.dart';
import '../config/api_config.dart';
import '../network/dio_client.dart';
import '../network/token_storage.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  getIt.registerLazySingleton(() => createDio());
  getIt.registerLazySingleton<Dio>(
    () => createDio(baseUrl: ApiConfig.apiSocialUrl),
    instanceName: 'second',
  );
  getIt.registerLazySingleton(() => TokenStorage());
  getIt.registerLazySingleton<UserStorage>(() => UserStorage());

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<InvestorsRemoteDataSource>(
    () => InvestorRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ClientRemoteDataSource>(
    () => ClientRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<BlacklistRemoteDataSources>(
    () => BlacklistRemoteDataSourcesImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<BankCardRemoteDataSource>(
    () => BankCardRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<QueueRemoteDataSource>(
    () => QueueRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<PaymentRemoteDataSources>(
    () => PaymentRemoteDataSourcesImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ScheduleRemoteDataSources>(
    () => ScheduleRemoteDataSourcesImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<CreditRemoteDataSource>(
    () => CreditRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<NoteRemoteDataSource>(
    () => NoteRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<NotificationsDataSource>(
    () => NotificationsDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<EmployeeRemoteDataSource>(
    () => EmployeeRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<CompanyRemoteDataSource>(
    () => CompanyRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AnalyticRemoteDataSource>(
    () => AnalyticRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ObjectTypeRemoteDataSource>(
    () => ObjectTypeRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<SoldProductRemoteDataSource>(
    () => SoldProductRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<CreditApplicationRemoteDataSource>(
    () => CreditApplicationRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerFactory(() => AuthCubit());
  getIt.registerFactory(() => InvestorsBloc());
  getIt.registerFactory(() => ClientsBloc());
  getIt.registerFactory(() => ClientApplicationsCubit());
  getIt.registerFactory(() => BlacklistBloc());
  getIt.registerFactory(() => BudgetIncomeBloc());
  getIt.registerFactory(() => BudgetExpenseBloc());
  getIt.registerFactory(() => QueueBloc());
  getIt.registerFactory(() => PaymentBloc());
  getIt.registerFactory(() => PaymentScheduleCubit());
  getIt.registerFactory(() => PaymentHistoryCubit());
  getIt.registerFactory(() => SchedulePreviewCubit());
  getIt.registerFactory(() => ScheduleBloc());
  getIt.registerFactory(() => CreditBloc());
  getIt.registerFactory(() => ProfileCubit());
  getIt.registerFactory(() => EmployeesBloc());
  getIt.registerFactory(() => CompanyCubit());
  getIt.registerFactory(() => PaymentStatsCubit());
  getIt.registerFactory(() => CreditStatsCubit());
  getIt.registerFactory(() => AnalyticItemsCubit());
  getIt.registerFactory(() => DebtDynamicCubit());
  getIt.registerFactory(() => InvestmentDynamicCubit());
  getIt.registerFactory(() => SellInfoCubit());
  getIt.registerFactory<ObjectTypeBloc>(() => ObjectTypeBloc());
  getIt.registerFactory(
    () => NotificationsCubit(getIt<NotificationsDataSource>()),
  );

  // Один сокет на приложение: живые уведомления, как в вебе.
  getIt.registerLazySingleton<NotificationSocket>(() => NotificationSocket());
}
