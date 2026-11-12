import 'package:waypay_mobile/blacklist_plus/core/network/token_storage.dart';
import 'package:waypay_mobile/blacklist_plus/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/screens/black_catalog_dossier_screen.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/screens/black_catalog_screen.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/screens/notifications_screen.dart';
import 'package:waypay_mobile/blacklist_plus/features/bottom_navigation_bar/main_layout.dart';
import 'package:waypay_mobile/blacklist_plus/features/info/privacy_policy_screen.dart';
import 'package:waypay_mobile/blacklist_plus/features/info/screens/privacy_policy_intro_screen.dart';
import 'package:waypay_mobile/blacklist_plus/features/profile/presentation/screens/profile_screen.dart';
import 'package:waypay_mobile/blacklist_plus/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final tokenStorage = TokenStorage();
      var isAuthenticated = await tokenStorage.isAuthenticated();
      final privacyAccepted = await tokenStorage.isPrivacyAccepted();

      final here = state.uri.toString();

      if (isAuthenticated) {
        final hasStoredAccess = await tokenStorage.hasStoredAccessToken();
        if (!hasStoredAccess) {
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
      if (here == '/' || here == Routes.phoneAuthScreen.toPath) {
        return Routes.blacklistScreen.toPath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const PhoneAuthScreen(userType: 'blacklist_plus'),
      ),
      GoRoute(
        path: Routes.phoneAuthScreen.toPath,
        name: Routes.phoneAuthScreen.toName,
        builder: (context, state) {
          final userType = state.extra as String? ?? 'blacklist_plus';
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainLayout(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.blacklistScreen.toPath,
                name: Routes.blacklistScreen.toName,
                builder: (context, state) => const BlackCatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.notificationsScreen.toPath,
                name: Routes.notificationsScreen.toName,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.profileScreen.toPath,
        name: Routes.profileScreen.toName,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.blackCatalogDossierScreen.toPath,
        name: Routes.blackCatalogDossierScreen.toName,
        builder: (context, state) {
          final item = state.extra as BlackCatalogItem?;
          if (item == null) {
            return const Scaffold(
              body: Center(child: Text('Запись не передана')),
            );
          }
          return BlackCatalogDossierScreen(initialItem: item);
        },
      ),
    ],
  );
}
