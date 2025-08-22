import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/features/admin_panel/presentation/cubit/company_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/analytic_items_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/debt_dynamic_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/investment_dynamic_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/sell_info_cubit.dart';
import 'package:waypay/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:waypay/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:waypay/features/blog/presentation/bloc/comment_bloc.dart';
import 'package:waypay/features/blog/presentation/cubit/profile_blog_cubit.dart';
import 'package:waypay/features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay/features/finance/presentation/bloc/budget/budget_expense_bloc.dart';
import 'package:waypay/features/finance/presentation/bloc/budget/budget_income_bloc.dart';
import 'package:waypay/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay/features/product/presentation/bloc/products_bloc.dart';
import 'package:waypay/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:waypay/features/profile/presentation/cubit/credit_stats_cubit.dart';
import 'package:waypay/features/profile/presentation/cubit/payment_stats_cubit.dart';
import 'package:waypay/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:waypay/features/todo/presentation/bloc/task_bloc.dart';
import 'package:waypay/features/network_error/screens/network_error_screen.dart';
import 'package:waypay/routes/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isOffline;
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      setState(() {
        isOffline = !hasConnection;
      });
    });
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    setState(() {
      isOffline = !hasConnection;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isOffline == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final app = isOffline!
        ? const MaterialApp(home: NetworkErrorScreen())
        : MaterialApp.router(
            title: 'WayPay',
            routerConfig: AppRouter.router,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                iconTheme: IconThemeData(color: Colors.white),
              ),
            ),
          );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()),
        BlocProvider(create: (_) => getIt<InvestorsBloc>()),
        BlocProvider(create: (_) => getIt<ProductsBloc>()),
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
        BlocProvider(create: (_) => getIt<TaskBloc>()),
        BlocProvider(create: (_) => getIt<BlogBloc>()),
        BlocProvider(create: (_) => getIt<CommentBloc>()),
        BlocProvider(create: (_) => getIt<ProfileBlogCubit>()),
        BlocProvider(create: (_) => getIt<ChatListBloc>()),
      ],
      child: app,
    );
  }
}
