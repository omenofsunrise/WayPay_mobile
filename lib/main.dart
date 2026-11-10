import 'package:waypay_mobile/core/notifications/push_notification_service.dart';
import 'package:waypay_mobile/core/widgets/live_notifications.dart';
import 'package:waypay_mobile/core/network/notification_socket.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/network/connectivity_checker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/admin_panel/presentation/cubit/company_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/debt_dynamic_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/investment_dynamic_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/sell_info_cubit.dart';
import 'package:waypay_mobile/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/screens/create_credit/new_credit_creation_screen.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/cubit/credit_creation_provider.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_expense_bloc.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_income_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:waypay_mobile/features/profile/presentation/cubit/credit_stats_cubit.dart';
import 'package:waypay_mobile/features/profile/presentation/cubit/payment_stats_cubit.dart';
import 'package:waypay_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:waypay_mobile/features/network_error/screens/network_error_screen.dart';
import 'package:waypay_mobile/routes/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/blacklist_plus/blacklist_plus_app.dart';
import 'package:waypay_mobile/blacklist_plus/core/di/dependency_injection.dart'
    as blacklist_plus;
import 'package:waypay_mobile/core/app_mode/app_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  await initDependencies();
  try {
    await blacklist_plus.initDependencies();
  } catch (e) {
    debugPrint('⚠️ ЧС+ не инициализировался: $e');
  }
  await AppModeController.instance.load();

  // Пуши не должны мешать запуску: если Firebase не настроен или разрешение
  // не выдано, приложение обязано открыться как обычно.
  try {
    await getIt<PushNotificationService>().init();
  } catch (e) {
    debugPrint('⚠️ Пуш-уведомления не поднялись: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool? isOffline;
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    // В вебе сокет оживает по visibilitychange; на телефоне аналог —
    // возврат приложения из фона.
    WidgetsBinding.instance.addObserver(this);
    _checkInitial();
    _subscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final hasConnection = await hasWorkingConnection(results);
      if (!mounted) return;
      setState(() {
        isOffline = !hasConnection;
      });
    });
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = await hasWorkingConnection(results);
    if (!mounted) return;
    setState(() {
      isOffline = !hasConnection;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      getIt<NotificationSocket>().reconnectNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isOffline == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final app = isOffline!
        ? const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: NetworkErrorScreen(),
          )
        : MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'waypay_mobile',
            routerConfig: AppRouter.router,
            // Уведомления по сокету должны всплывать на любом экране.
            builder: (context, child) =>
                LiveNotifications(child: child ?? const SizedBox.shrink()),
            theme: WayPayTheme.light,
          );

    return ValueListenableBuilder<AppMode>(
      valueListenable: AppModeController.instance,
      builder: (context, mode, _) {
        if (mode == AppMode.blacklistPlus && !isOffline!) {
          return const BlacklistPlusApp();
        }
        return _buildWayPay(app);
      },
    );
  }

  Widget _buildWayPay(Widget app) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()),
        BlocProvider(create: (_) => getIt<InvestorsBloc>()),
        BlocProvider(create: (_) => getIt<BudgetIncomeBloc>()),
        BlocProvider(create: (_) => getIt<BudgetExpenseBloc>()),
        BlocProvider(create: (_) => getIt<CreditBloc>()),
        BlocProvider(create: (_) => getIt<ProfileCubit>()),
        BlocProvider(create: (_) => getIt<EmployeesBloc>()),
        BlocProvider(create: (_) => getIt<CompanyCubit>()),
        BlocProvider(create: (_) => getIt<PaymentStatsCubit>()),
        BlocProvider(create: (_) => getIt<CreditStatsCubit>()),
        BlocProvider(create: (_) => getIt<AnalyticItemsCubit>()),
        BlocProvider(create: (_) => getIt<DebtDynamicCubit>()),
        BlocProvider(create: (_) => getIt<InvestmentDynamicCubit>()),
        BlocProvider(create: (_) => getIt<SellInfoCubit>()),
        BlocProvider(create: (context) => ObjectTypeBloc()),
        BlocProvider(create: (_) => CreditCreationCubit()),
        BlocProvider<ClientsBloc>(
          create: (context) => getIt<ClientsBloc>(),
          child: NewCreditCreationScreen(),
        ),
      ],
      child: app,
    );
  }
}
