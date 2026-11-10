import 'package:waypay_mobile/blacklist_plus/core/storage/user_storage.dart';
import 'package:waypay_mobile/blacklist_plus/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/blacklist_plus/features/auth/data/data_sources/auth_remote_data_source_impl.dart';
import 'package:waypay_mobile/blacklist_plus/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/data_sources/black_catalog_remote_data_source_impl.dart';
import 'package:waypay_mobile/blacklist_plus/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:waypay_mobile/blacklist_plus/features/profile/data/data_sources/employee_remote_data_source_impl.dart';
import 'package:waypay_mobile/blacklist_plus/features/calc/data/calc_preset_service.dart';
import 'package:waypay_mobile/blacklist_plus/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:waypay_mobile/blacklist_plus/features/stats/data/debt_export_service.dart';
import 'package:waypay_mobile/blacklist_plus/features/stats/data/debt_reminder_service.dart';
import 'package:waypay_mobile/blacklist_plus/features/stats/data/local_debt_service.dart';
import 'package:waypay_mobile/blacklist_plus/features/stats/data/local_stats_service.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../network/token_storage.dart';

// Отдельный контейнер: зависимости ЧС+ не пересекаются с WayPay.
final getIt = GetIt.asNewInstance();

Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<LocalStatsService>(LocalStatsService(prefs));

  final reminderService = DebtReminderService();
  await reminderService.init();
  getIt.registerSingleton<DebtReminderService>(reminderService);

  getIt.registerSingleton<LocalDebtService>(
    LocalDebtService(prefs, reminderService),
  );
  getIt.registerSingleton<DebtExportService>(DebtExportService());
  getIt.registerSingleton<CalcPresetService>(CalcPresetService(prefs));

  getIt.registerLazySingleton(() => createDio());
  getIt.registerLazySingleton(() => TokenStorage());
  getIt.registerLazySingleton<UserStorage>(() => UserStorage());

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<EmployeeRemoteDataSource>(
    () => EmployeeRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<BlackCatalogRemoteDataSource>(
    () => BlackCatalogRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerFactory(() => AuthCubit());
  getIt.registerFactory(() => ProfileCubit());
}
