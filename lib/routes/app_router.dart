import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:waypay_mobile/core/network/token_storage.dart';

import 'package:waypay_mobile/features/auth/presentation/screens/confirmation_screen.dart';
import 'package:waypay_mobile/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:waypay_mobile/features/auth/presentation/screens/pin_code_screen.dart';

import 'package:waypay_mobile/features/bottom_navigation_bar/main_layout.dart';
import 'package:waypay_mobile/features/blog/presentation/screens/blog_screen.dart';
import 'package:waypay_mobile/features/credit/presentation/screens/create_credit/custom_page_transitions.dart';
import 'package:waypay_mobile/features/credit/presentation/screens/create_credit/new_credit_creation_screen.dart';
import 'package:waypay_mobile/features/credit/presentation/screens/credit_screen.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_expense_bloc.dart';
import 'package:waypay_mobile/features/finance/presentation/bloc/budget/budget_income_bloc.dart';
import 'package:waypay_mobile/features/finance/presentation/screens/budget_screen.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/credit_application_model.dart';
import 'package:waypay_mobile/features/home/presentation/cubit/client_applications/client_applications_cubit.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_application_detail_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_applications_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_create_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_detail_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_list_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_black_catalog_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_blacklist_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/main_client_screen.dart';
import 'package:waypay_mobile/features/home/presentation/screens/queue_list_screen.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investor_pool_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investor_pool_detail_screen.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investor_pool_screen.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investors_hub_screen.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investors_screen.dart';
import 'package:waypay_mobile/features/product/presentation/screens/product_screen.dart';
import 'package:waypay_mobile/features/finance/presentation/screens/finance_main_screen.dart';
import 'package:waypay_mobile/features/finance/presentation/screens/budget_applications_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/profile_statistics_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/active_sessions_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/employees_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/add_employee_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:waypay_mobile/features/todo/presentation/screen/todo_screen.dart';
import 'package:waypay_mobile/features/chat/presentation/screens/all_chat_screen.dart';
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
import 'package:waypay_mobile/features/clients/presentation/cubit/black_catalog/black_catalog_cubit.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final tokenStorage = TokenStorage();
      final isAuthenticated = await tokenStorage.isAuthenticated();
      final hasPinCode = await tokenStorage.getPinCode() != null;

      final here = state.uri.toString();

      if (!isAuthenticated) {
        if (here == '/') return Routes.phoneAuthScreen.toPath;

        final guestAllowed = {
          Routes.phoneAuthScreen.toPath,
          Routes.confirmationScreen.toPath,
        };
        if (!guestAllowed.contains(here)) {
          return Routes.phoneAuthScreen.toPath;
        }
        return null;
      }
      if (hasPinCode) {
        if (here == '/' ||
            here == Routes.phoneAuthScreen.toPath ||
            here == Routes.confirmationScreen.toPath) {
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
        pageBuilder: (context, state) =>
            SlideLeftTransition(child: NewCreditCreationScreen()),
      ),
      GoRoute(
        path: Routes.newCreditSchedulesScreen.toPath,
        name: Routes.newCreditSchedulesScreen.toName,
        pageBuilder: (context, state) =>
            SlideLeftTransition(child: NewCreditCreationScreen()),
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
        path: Routes.confirmationScreen.toPath,
        name: Routes.confirmationScreen.toName,
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return ConfirmationScreen(phone: phone);
        },
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
        builder: (context, state) => BlocProvider(
          create: (_) =>
              InvestorPoolBloc()..add(LoadInvestorPool(refresh: true)),
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

      GoRoute(
        path: Routes.productScreen.toPath,
        name: Routes.productScreen.toName,
        builder: (context, state) => const ProductsScreen(),
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
                      GoRoute(
                        path: Routes.budgetScreen.toPath,
                        name: Routes.budgetScreen.toName,
                        builder: (context, state) => const BudgetScreen(),
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
                    path: Routes.blackCatalogScreen.toPath,
                    name: Routes.blackCatalogScreen.toName,
                    builder: (context, state) => BlocProvider(
                      create: (_) => BlackCatalogCubit(),
                      child: const ClientBlackCatalogScreen(),
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
                      child: const ScheduleScreen(),
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
                path: Routes.todoScreen.toPath,
                name: Routes.todoScreen.toName,
                builder: (context, state) => const TodoScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.chatScreen.toPath,
                name: Routes.chatScreen.toName,
                builder: (context, state) => const AllChatScreen(),
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
                path: Routes.blogScreen.toPath,
                name: Routes.blogScreen.toName,
                builder: (context, state) => const BlogScreen(),
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
