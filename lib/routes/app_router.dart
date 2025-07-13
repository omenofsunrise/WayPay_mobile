import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/features/auth/presentation/screens/confirmation_screen.dart';
import 'package:waypay/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:waypay/features/auth/presentation/screens/pin_code_screen.dart';
import 'package:waypay/features/auth/presentation/screens/user_type_selection_screen.dart';
import 'package:waypay/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay/features/investors/presentation/screens/investors_screen.dart';
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

      if (isAuthenticated && hasPinCode && state.uri.toString() == '/') {
        return Routes.pinCodeScreen.toPath;
      }

      if (isAuthenticated && state.uri.toString() == '/') {
        return Routes.userTypeSelectionScreen.toPath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const UserTypeSelectionScreen(),
      ),
      GoRoute(
        path: Routes.userTypeSelectionScreen.toPath,
        name: Routes.userTypeSelectionScreen.toName,
        builder: (context, state) => const UserTypeSelectionScreen(),
      ),
      GoRoute(
        path: Routes.phoneAuthScreen.toPath,
        name: Routes.phoneAuthScreen.toName,
        builder: (context, state) {
          final userType = state.extra as String? ?? '';
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
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
