import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/features/admin_panel/data/data_sources/company_remote_data_source.dart';
import 'package:waypay/features/admin_panel/data/data_sources/company_remote_data_source_impl.dart';
import 'package:waypay/features/admin_panel/presentation/cubit/company_cubit.dart';
import 'package:waypay/features/analytics/data/data_sources/analytic_remote_data_source.dart';
import 'package:waypay/features/analytics/data/data_sources/analytic_remote_data_source_impl.dart';
import 'package:waypay/features/analytics/presentation/cubit/analytic_items_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/debt_dynamic_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/investment_dynamic_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/sell_info_cubit.dart';
import 'package:waypay/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay/features/auth/data/data_sources/auth_remote_data_source_impl.dart';
import 'package:waypay/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:waypay/features/blog/data/data_sources/blog_remote_data_sources.dart';
import 'package:waypay/features/blog/data/data_sources/blog_remote_data_sources_impl.dart';
import 'package:waypay/features/blog/data/data_sources/profile_blog_remote_data_sources.dart';
import 'package:waypay/features/blog/data/data_sources/profile_blog_remote_data_sources_impl.dart';
import 'package:waypay/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:waypay/features/blog/presentation/bloc/comment_bloc.dart';
import 'package:waypay/features/blog/presentation/cubit/profile_blog_cubit.dart';
import 'package:waypay/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay/features/chat/data/data_source/chat/chat_remote_data_source_impl.dart';
import 'package:waypay/features/chat/data/data_source/message/message_remote_data_source.dart';
import 'package:waypay/features/chat/data/data_source/message/message_remote_data_source_impl.dart';
import 'package:waypay/features/chat/data/service/chat_hub_service.dart';
import 'package:waypay/features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'package:waypay/features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';
import 'package:waypay/features/clients/data/data_sources/blacklist/blacklist_remote_data_sources.dart';
import 'package:waypay/features/clients/data/data_sources/blacklist/blacklist_remote_data_sources_impl.dart';
import 'package:waypay/features/clients/presentation/bloc/blacklist/blacklist_bloc.dart';
import 'package:waypay/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay/features/clients/data/data_sources/clients/clients_remote_data_source_impl.dart';
import 'package:waypay/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay/features/credit/data/data_source/credit_remote_data_source_impl.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay/features/finance/data/data_source/budget_remote_data_source.dart';
import 'package:waypay/features/finance/data/data_source/budget_remote_data_source_impl.dart';
import 'package:waypay/features/finance/presentation/bloc/budget/budget_expense_bloc.dart';
import 'package:waypay/features/finance/presentation/bloc/budget/budget_income_bloc.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source_impl.dart';
import 'package:waypay/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay/features/note/data/data_sources/note_remote_data_source_impl.dart';
import 'package:waypay/features/product/data/data_sources/products_remote_data_source.dart';
import 'package:waypay/features/product/data/data_sources/products_remote_data_source_impl.dart';
import 'package:waypay/features/product/presentation/bloc/products_bloc.dart';
import 'package:waypay/features/clients/data/data_sources/queue/queue_remote_data_source.dart';
import 'package:waypay/features/clients/data/data_sources/queue/queue_remote_data_source_impl.dart';
import 'package:waypay/features/clients/presentation/bloc/queue/queue_bloc.dart';
import 'package:waypay/features/payment/data/data_sources/schedule/schedule_remote_data_sources.dart';
import 'package:waypay/features/payment/data/data_sources/schedule/schedule_remote_data_sources_impl.dart';
import 'package:waypay/features/payment/presentation/bloc/schedule/schedule_bloc.dart';
import 'package:waypay/features/payment/data/data_sources/expected/payment_remote_data_sources.dart';
import 'package:waypay/features/payment/data/data_sources/expected/payment_remote_data_sources_impl.dart';
import 'package:waypay/features/payment/presentation/bloc/expected/payment_bloc.dart';
import 'package:waypay/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:waypay/features/profile/data/data_sources/employee_remote_data_source_impl.dart';
import 'package:waypay/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:waypay/features/profile/presentation/cubit/credit_stats_cubit.dart';
import 'package:waypay/features/profile/presentation/cubit/payment_stats_cubit.dart';
import 'package:waypay/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:waypay/features/todo/data/data_soucres/task_remote_data_source.dart';
import 'package:waypay/features/todo/data/data_soucres/task_remote_data_source_impl.dart';
import 'package:waypay/features/todo/presentation/bloc/task_bloc.dart';
import '../network/dio_client.dart';
import '../network/token_storage.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  getIt.registerLazySingleton(() => createDio());
  getIt.registerLazySingleton<Dio>(
    () => createDio(baseUrl: 'http://test.waypay.one:5003'),
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
  getIt.registerLazySingleton<ProductsRemoteDataSource>(
    () => ProductsRemoteDataSourceImpl(getIt<Dio>()),
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
  getIt.registerLazySingleton<EmployeeRemoteDataSource>(
    () => EmployeeRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<CompanyRemoteDataSource>(
    () => CompanyRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AnalyticRemoteDataSource>(
    () => AnalyticRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(getIt<Dio>(instanceName: 'second')),
  );
  getIt.registerLazySingleton<BlogRemoteDataSources>(
    () => BlogRemoteDataSourcesImpl(getIt<Dio>(instanceName: 'second')),
  );
  getIt.registerLazySingleton<ProfileBlogRemoteDataSources>(
    () => ProfileBlogRemoteDataSourcesImpl(getIt<Dio>(instanceName: 'second')),
  );
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(getIt<Dio>(instanceName: 'second')),
  );
  getIt.registerLazySingleton<MessageRemoteDataSource>(
    () => MessageRemoteDataSourceImpl(getIt<Dio>(instanceName: 'second')),
  );
  getIt.registerLazySingleton<ChatHubService>(
    () => ChatHubService(
      baseUrl: 'http://test.waypay.one:5003',
      tokenProvider: () async => await getIt<TokenStorage>().getAccessToken(),
    ),
  );

  getIt.registerFactory(() => AuthCubit());
  getIt.registerFactory(() => InvestorsBloc());
  getIt.registerFactory(() => ClientsBloc());
  getIt.registerFactory(() => BlacklistBloc());
  getIt.registerFactory(() => ProductsBloc());
  getIt.registerFactory(() => BudgetIncomeBloc());
  getIt.registerFactory(() => BudgetExpenseBloc());
  getIt.registerFactory(() => QueueBloc());
  getIt.registerFactory(() => PaymentBloc());
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
  getIt.registerFactory(() => TaskBloc());
  getIt.registerFactory(() => BlogBloc());
  getIt.registerFactory(() => CommentBloc());
  getIt.registerFactory(() => ProfileBlogCubit());
  getIt.registerFactory(
    () => ChatListBloc(
      api: getIt<ChatRemoteDataSource>(),
      hub: getIt<ChatHubService>(),
    ),
  );
}
