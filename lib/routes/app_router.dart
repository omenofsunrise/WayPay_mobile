import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/debt_dynamic_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/investment_dynamic_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/sell_info_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/screens/analytic_screen.dart';
import 'package:waypay_mobile/features/admin_panel/presentation/screen/company_data_screen.dart';
import 'package:waypay_mobile/features/admin_panel/presentation/screen/control_panel_screen.dart';
import 'package:waypay_mobile/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:waypay_mobile/features/auth/presentation/screens/pin_code_screen.dart';
import 'package:waypay_mobile/features/bottom_navigation_bar/main_layout.dart';
import 'package:waypay_mobile/features/credit/presentation/screens/create_credit/new_credit_creation_screen.dart';
import 'package:waypay_mobile/features/credit/presentation/screens/credit_screen.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_expense_bloc.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_income_bloc.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/credit_application_model.dart';
import 'package:waypay_mobile/features/home/presentation/cubit/client_applications/client_applications_cubit.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_application_detail_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_applications_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_create_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_detail_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_list_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_blacklist_screen.dart';
import 'package:waypay_mobile/features/clients/presentation/screens/blacklist_plus_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/main_client_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/queue_list_screen.dart';
import 'package:waypay_mobile/features/info/privacy_policy_screen.dart';
import 'package:waypay_mobile/features/info/screens/privacy_policy_intro_screen.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investor_pool_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investor_pool_detail_screen.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investor_pool_screen.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investors_hub_screen.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investors_screen.dart';
import 'package:waypay_mobile/features/finance/presentation/screens/finance_main_screen.dart';
import 'package:waypay_mobile/features/finance/presentation/screens/budget_applications_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/profile_statistics_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/active_sessions_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/employees_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/add_employee_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:waypay_mobile/features/calc/calculator_page.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/schedule_model.dart';
import 'package:waypay_mobile/features/payment/presentation/bloc/expected/payment_bloc.dart';
import 'package:waypay_mobile/features/payment/presentation/bloc/schedule/schedule_bloc.dart';
import 'package:waypay_mobile/features/payment/presentation/cubit/payment_schedule_cubit.dart';
import 'package:waypay_mobile/features/payment/presentation/cubit/payment_history_cubit.dart';
import 'package:waypay_mobile/features/payment/presentation/cubit/schedule_preview_cubit.dart';
import 'package:waypay_mobile/features/payment/presentation/screen/payment_analytics_screen.dart';
import 'package:waypay_mobile/features/payment/presentation/screen/payment_detail_screen.dart';
import 'package:waypay_mobile/features/payment/presentation/screen/payment_history_screen.dart';
import 'package:waypay_mobile/features/payment/presentation/screen/payment_income_screen.dart';
import 'package:waypay_mobile/features/payment/presentation/screen/payment_screen.dart';
import 'package:waypay_mobile/features/payment/presentation/screen/schedule_screen.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';

import 'package:waypay_mobile/routes/routes.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/blacklist/blacklist_bloc.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';

class AppRouter {
  /// Нужен, чтобы показывать сообщения из корня приложения: у контекста
  /// внутри MaterialApp.builder нет Overlay, он лежит ниже, в Navigator.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final tokenStorage = TokenStorage();
      var isAuthenticated = await tokenStorage.isAuthenticated();
      final privacyAccepted = await tokenStorage.isPrivacyAccepted();
      final hasPinCode = await tokenStorage.getPinCode() != null;

      final here = state.uri.toString();

      if (isAuthenticated) {
        final access = await tokenStorage.getAccessToken();
        if (access == null) {
          await tokenStorage.setAuthenticated(false);
          isAuthenticated = false;
        }
      }

      if (!privacyAccepted) {
        final allowed = {
          Routes.privacyPolicyIntroScreen.toPath,
          Routes.privacyPolicyScreen.toPath,
        };
        final location = state.uri.toString();
        if (!allowed.contains(location)) {
          return Routes.privacyPolicyIntroScreen.toPath;
        }
        return null;
      }

      if (!isAuthenticated) {
        if (here == '/') return Routes.phoneAuthScreen.toPath;

        final guestAllowed = {Routes.phoneAuthScreen.toPath};
        if (!guestAllowed.contains(here)) {
          return Routes.phoneAuthScreen.toPath;
        }
        return null;
      }
      if (hasPinCode) {
        if (here == '/' || here == Routes.phoneAuthScreen.toPath) {
          return Routes.pinCodeScreen.toPath;
        }
        return null;
      }

      if (here == '/' || here == Routes.phoneAuthScreen.toPath) {
        return Routes.pinCodeScreen.toPath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const PhoneAuthScreen(userType: 'employee'),
      ),
      GoRoute(
        path: Routes.newCreditProductsScreen.toPath,
        name: Routes.newCreditProductsScreen.toName,
        builder: (context, state) => const NewCreditCreationScreen(),
      ),
      GoRoute(
        path: Routes.newCreditSchedulesScreen.toPath,
        name: Routes.newCreditSchedulesScreen.toName,
        builder: (context, state) => const NewCreditCreationScreen(),
      ),
      GoRoute(
        path: Routes.phoneAuthScreen.toPath,
        name: Routes.phoneAuthScreen.toName,
        builder: (context, state) {
          final userType = state.extra as String? ?? 'employee';
          return PhoneAuthScreen(userType: userType);
        },
      ),
      GoRoute(
        path: Routes.privacyPolicyIntroScreen.toPath,
        name: Routes.privacyPolicyIntroScreen.toName,
        builder: (context, state) => const PrivacyPolicyIntroScreen(),
      ),
      GoRoute(
        path: Routes.privacyPolicyScreen.toPath,
        name: Routes.privacyPolicyScreen.toName,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      GoRoute(
        path: Routes.pinCodeScreen.toPath,
        name: Routes.pinCodeScreen.toName,
        builder: (context, state) => const PinCodeScreen(),
      ),

      GoRoute(
        path: Routes.investorsScreen.toPath,
        name: Routes.investorsScreen.toName,
        pageBuilder: (context, state) {
          return MaterialPage(
            child: BlocProvider(
              create: (_) =>
                  InvestorsBloc()..add(LoadInvestorsEvent(refresh: true)),
              child: const InvestorsScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.investorPoolScreen.toPath,
        name: Routes.investorPoolScreen.toName,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  InvestorPoolBloc()..add(LoadInvestorPool(refresh: true)),
            ),
            BlocProvider(
              create: (_) =>
                  InvestorsBloc()..add(LoadInvestorsEvent(refresh: true)),
            ),
          ],
          child: const InvestorPoolScreen(),
        ),
      ),
      GoRoute(
        path: Routes.investorPoolDetailScreen.toPath,
        name: Routes.investorPoolDetailScreen.toName,
        builder: (context, state) {
          final pool = state.extra as InvestorPoolModel?;
          if (pool == null) {
            return const Scaffold(body: Center(child: Text('Нет данных пула')));
          }
          return InvestorPoolDetailScreen(pool: pool);
        },
      ),

      GoRoute(
        path: Routes.profileScreen.toPath,
        name: Routes.profileScreen.toName,
        builder: (context, state) {
          final employeeId = state.extra as int?;
          return ProfileScreen(employeeId: employeeId);
        },
      ),
      GoRoute(
        path: Routes.companyDataScreen.toPath,
        name: Routes.companyDataScreen.toName,
        builder: (context, state) => const CompanyDataScreen(),
      ),
      GoRoute(
        path: Routes.controlPanelScreen.toPath,
        name: Routes.controlPanelScreen.toName,
        builder: (context, state) => const ControlPanelScreen(),
      ),
      GoRoute(
        path: Routes.blacklistPlusScreen.toPath,
        name: Routes.blacklistPlusScreen.toName,
        builder: (context, state) => const BlacklistPlusScreen(),
      ),
      GoRoute(
        path: Routes.profileActiveSessionsScreen.toPath,
        name: Routes.profileActiveSessionsScreen.toName,
        builder: (context, state) => const ActiveSessionsScreen(),
      ),
      GoRoute(
        path: Routes.profileEmployeesScreen.toPath,
        name: Routes.profileEmployeesScreen.toName,
        builder: (context, state) => const EmployeesScreen(),
      ),
      GoRoute(
        path: Routes.profileAddEmployeeScreen.toPath,
        name: Routes.profileAddEmployeeScreen.toName,
        builder: (context, state) {
          final bloc = state.extra as EmployeesBloc?;
          if (bloc == null) {
            return const Scaffold(
              body: Center(child: Text('Нет данных для создания')),
            );
          }
          return AddEmployeeScreen(employeesBloc: bloc);
        },
      ),
      GoRoute(
        path: Routes.profileStatsScreen.toPath,
        name: Routes.profileStatsScreen.toName,
        builder: (context, state) {
          final employeeId = state.extra as int?;
          return ProfileStatisticsScreen(employeeId: employeeId);
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.homeScreen.toPath,
                name: Routes.homeScreen.toName,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: Routes.mainClientScreen.toPath,
                    name: Routes.mainClientScreen.toName,
                    builder: (context, state) => const MainClientScreen(),
                  ),
                  GoRoute(
                    path: Routes.clientListScreen.toPath,
                    name: Routes.clientListScreen.toName,
                    builder: (context, state) => BlocProvider(
                      create: (_) => ClientsBloc(),
                      child: const ClientListScreen(),
                    ),
                  ),
                  GoRoute(
                    path: Routes.clientCreateScreen.toPath,
                    name: Routes.clientCreateScreen.toName,
                    builder: (context, state) => BlocProvider(
                      create: (_) => ClientsBloc(),
                      child: const ClientCreateScreen(),
                    ),
                  ),
                  GoRoute(
                    path: Routes.clientDetailScreen.toPath,
                    name: Routes.clientDetailScreen.toName,
                    builder: (context, state) {
                      final client = state.extra as ClientModel?;
                      return ClientDetailScreen(client: client);
                    },
                  ),
                  GoRoute(
                    path: Routes.clientApplicationsScreen.toPath,
                    name: Routes.clientApplicationsScreen.toName,
                    builder: (context, state) => BlocProvider(
                      create: (_) => ClientApplicationsCubit(),
                      child: const ClientApplicationsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: Routes.clientApplicationDetailScreen.toPath,
                    name: Routes.clientApplicationDetailScreen.toName,
                    builder: (context, state) {
                      final application = state.extra as CreditApplicationModel;
                      return ClientApplicationDetailScreen(
                        application: application,
                      );
                    },
                  ),
                  GoRoute(
                    path: Routes.queueListScreen.toPath,
                    name: Routes.queueListScreen.toName,
                    builder: (context, state) => BlocProvider(
                      create: (_) => ClientsBloc(),
                      child: const QueueListScreen(),
                    ),
                  ),
                  GoRoute(
                    path: Routes.financeScreen.toPath,
                    name: Routes.financeScreen.toName,
                    builder: (context, state) => const FinanceMainScreen(),
                    routes: [
                      GoRoute(
                        path: Routes.budgetApplicationsScreen.toPath,
                        name: Routes.budgetApplicationsScreen.toName,
                        builder: (context, state) => MultiBlocProvider(
                          providers: [
                            BlocProvider(create: (_) => BudgetIncomeBloc()),
                            BlocProvider(create: (_) => BudgetExpenseBloc()),
                          ],
                          child: const BudgetApplicationsScreen(),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: Routes.blacklistScreen.toPath,
                    name: Routes.blacklistScreen.toName,
                    builder: (context, state) => BlocProvider(
                      create: (_) => BlacklistBloc(),
                      child: const ClientBlacklistScreen(),
                    ),
                  ),

                  GoRoute(
                    path: Routes.paymentScreen.toPath,
                    name: Routes.paymentScreen.toName,
                    builder: (context, state) => MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (_) => PaymentBloc()
                            ..add(
                              LoadPayment(refresh: true, page: 1, pageSize: 10),
                            ),
                        ),
                        BlocProvider(
                          create: (_) =>
                              PaymentScheduleCubit()
                                ..load(year: DateTime.now().year),
                        ),
                        BlocProvider(create: (_) => SchedulePreviewCubit()),
                        BlocProvider(
                          create: (_) => PaymentHistoryCubit()..load(limit: 2),
                        ),
                      ],
                      child: const PaymentScreen(),
                    ),
                  ),
                  GoRoute(
                    path: Routes.scheduleScreen.toPath,
                    name: Routes.scheduleScreen.toName,
                    builder: (context, state) => BlocProvider(
                      create: (_) => ScheduleBloc(),
                      child: () {
                        final extra = state.extra;
                        if (extra is ScheduleScreenArgs) {
                          return ScheduleScreen(
                            creditId: extra.creditId,
                            clientPhone: extra.clientPhone,
                          );
                        }
                        return ScheduleScreen(
                          creditId: extra is int ? extra : null,
                        );
                      }(),
                    ),
                  ),
                  GoRoute(
                    path: Routes.paymentHistoryScreen.toPath,
                    name: Routes.paymentHistoryScreen.toName,
                    builder: (context, state) => BlocProvider(
                      create: (_) => PaymentBloc()
                        ..add(
                          LoadPayment(refresh: true, page: 1, pageSize: 10),
                        ),
                      child: const PaymentHistoryScreen(),
                    ),
                  ),
                  GoRoute(
                    path: Routes.paymentDetailScreen.toPath,
                    name: Routes.paymentDetailScreen.toName,
                    builder: (context, state) {
                      final extra = state.extra;
                      if (extra is ScheduleModel) {
                        return PaymentDetailScreen(schedule: extra);
                      } else if (extra is PaymentItemModel) {
                        return PaymentDetailScreen(payment: extra);
                      }
                      return const Scaffold(
                        body: Center(child: Text('Нет данных для платежа')),
                      );
                    },
                  ),
                  GoRoute(
                    path: Routes.paymentAnalyticsScreen.toPath,
                    name: Routes.paymentAnalyticsScreen.toName,
                    builder: (context, state) => BlocProvider(
                      create: (_) =>
                          PaymentScheduleCubit()
                            ..load(year: DateTime.now().year),
                      child: const PaymentAnalyticsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: Routes.analyticsScreen.toPath,
                    name: Routes.analyticsScreen.toName,
                    builder: (context, state) => MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (_) => AnalyticItemsCubit()),
                        BlocProvider(create: (_) => InvestmentDynamicCubit()),
                        BlocProvider(create: (_) => SellInfoCubit()),
                        BlocProvider(create: (_) => DebtDynamicCubit()),
                      ],
                      child: const AnalyticsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: Routes.paymentIncomeScreen.toPath,
                    name: Routes.paymentIncomeScreen.toName,
                    builder: (context, state) => BlocProvider(
                      create: (_) => PaymentBloc(),
                      child: const PaymentIncomeScreen(),
                    ),
                  ),
                  GoRoute(
                    path: Routes.investorsHubScreen.toPath,
                    name: Routes.investorsHubScreen.toName,
                    builder: (context, state) => const InvestorsHubScreen(),
                  ),
                  GoRoute(
                    path: Routes.creditsScreen.toPath,
                    name: Routes.creditsScreen.toName,
                    builder: (context, state) => const CreditsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.newCreditDetailsScreen.toPath,
                name: Routes.newCreditDetailsScreen.toName,
                builder: (context, state) => const NewCreditCreationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.calculatorScreen.toPath,
                name: Routes.calculatorScreen.toName,
                builder: (context, state) => const CalculatorScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
