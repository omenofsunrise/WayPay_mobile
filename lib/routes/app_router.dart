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
import 'package:waypay_mobile/features/finance/presentation/screens/budget_screen.dart';
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
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investors_screen.dart';
import 'package:waypay_mobile/features/product/presentation/screens/product_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:waypay_mobile/features/todo/presentation/screen/todo_screen.dart';
import 'package:waypay_mobile/features/chat/presentation/screens/all_chat_screen.dart';
import 'package:waypay_mobile/features/calc/calculator_page.dart';

import 'package:waypay_mobile/routes/routes.dart';
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
        path: Routes.newCreditDetailsScreen.toPath,
        name: Routes.newCreditDetailsScreen.toName,
        pageBuilder: (context, state) =>
            SlideLeftTransition(child: NewCreditCreationScreen()),
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
        path: Routes.profileScreen.toPath,
        name: Routes.profileScreen.toName,
        builder: (context, state) {
          final employeeId = state.extra as int?;
          return ProfileScreen(employeeId: employeeId);
        },
      ),

      GoRoute(
        path: Routes.productScreen.toPath,
        name: Routes.productScreen.toName,
        builder: (context, state) => const ProductsScreen(),
      ),

      GoRoute(
        path: Routes.budgetScreen.toPath,
        name: Routes.budgetScreen.toName,
        builder: (context, state) => const BudgetScreen(),
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
                    builder: (context, state) => const ClientCreateScreen(),
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
                    builder: (context, state) =>
                        const ClientApplicationsScreen(),
                  ),
                  GoRoute(
                    path: Routes.clientApplicationDetailScreen.toPath,
                    name: Routes.clientApplicationDetailScreen.toName,
                    builder: (context, state) {
                      final application = state.extra as ClientApplication;
                      return ClientApplicationDetailScreen(
                        application: application,
                      );
                    },
                  ),
                  GoRoute(
                    path: Routes.queueListScreen.toPath,
                    name: Routes.queueListScreen.toName,
                    builder: (context, state) => const QueueListScreen(),
                  ),
                  GoRoute(
                    path: Routes.blacklistScreen.toPath,
                    name: Routes.blacklistScreen.toName,
                    builder: (context, state) => const ClientBlacklistScreen(),
                  ),
                  GoRoute(
                    path: Routes.blackCatalogScreen.toPath,
                    name: Routes.blackCatalogScreen.toName,
                    builder: (context, state) =>
                        const ClientBlackCatalogScreen(),
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
                path: Routes.creditsScreen.toPath,
                name: Routes.creditsScreen.toName,
                builder: (context, state) => const CreditsScreen(),
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
