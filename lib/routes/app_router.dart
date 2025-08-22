import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:waypay/core/network/token_storage.dart';

import 'package:waypay/features/auth/presentation/screens/confirmation_screen.dart';
import 'package:waypay/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:waypay/features/auth/presentation/screens/pin_code_screen.dart';

import 'package:waypay/features/credit/presentation/screens/credit_screen.dart';
import 'package:waypay/features/finance/presentation/screens/budget_screen.dart';
import 'package:waypay/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay/features/investors/presentation/screens/investors_screen.dart';
import 'package:waypay/features/product/presentation/screens/product_screen.dart';
import 'package:waypay/features/profile/presentation/screens/profile_screen.dart';

import 'package:waypay/routes/routes.dart';

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

      GoRoute(
        path: Routes.creditsScreen.toPath,
        name: Routes.creditsScreen.toName,
        builder: (context, state) => const CreditsScreen(),
      ),
    ],
  );
}
