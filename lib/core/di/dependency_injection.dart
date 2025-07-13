import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/features/auth/data/data_sources/auth_remote_data_source_impl.dart';
import 'package:waypay/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:waypay/features/blacklist/data/data_sources/blacklist_remote_data_sources.dart';
import 'package:waypay/features/blacklist/data/data_sources/blacklist_remote_data_sources_impl.dart';
import 'package:waypay/features/blacklist/presentation/bloc/blacklist_bloc.dart';
import 'package:waypay/features/clients/data/data_sources/clients_remote_data_source.dart';
import 'package:waypay/features/clients/data/data_sources/clients_remote_data_source_impl.dart';
import 'package:waypay/features/clients/presentation/bloc/clients_bloc.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source_impl.dart';
import 'package:waypay/features/investors/presentation/bloc/investors_bloc.dart';
import '../network/dio_client.dart';
import '../network/token_storage.dart';
import '../../features/auth/data/data_sources/auth_remote_data_source.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  getIt.registerLazySingleton(() => createDio());

  getIt.registerLazySingleton(() => TokenStorage());

  getIt.registerLazySingleton<UserStorage>(() => UserStorage());

  getIt.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(getIt<Dio>()));

  getIt.registerLazySingleton<InvestorsRemoteDataSource>(() => InvestorRemoteDataSourceImpl(getIt<Dio>()));
  getIt.registerLazySingleton<ClientRemoteDataSource>(() => ClientRemoteDataSourceImpl(getIt<Dio>()));
  getIt.registerLazySingleton<BlacklistRemoteDataSources>(() => BlacklistRemoteDataSourcesImpl(getIt<Dio>()));

  getIt.registerFactory(() => AuthCubit());
  getIt.registerFactory(() => InvestorsBloc());
  getIt.registerFactory(() => ClientsBloc());
  getIt.registerFactory(() => BlacklistBloc());
}
