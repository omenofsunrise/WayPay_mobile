import 'package:go_router/go_router.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/features/auth/presentation/screens/confirmation_screen.dart';
import 'package:waypay/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:waypay/features/auth/presentation/screens/pin_code_screen.dart';
import 'package:waypay/features/bottom_navigation_bar/main_layout.dart';
import 'package:waypay/features/calc/calculator_page.dart';
import 'package:waypay/features/chat/presentation/screens/all_chat_screen.dart';
import 'package:waypay/features/credit/presentation/screens/credit_screen.dart';
import 'package:waypay/features/home/presentation/screens/home_screen.dart';
import 'package:waypay/features/blog/presentation/screens/blog_screen.dart';
import 'package:waypay/features/todo/presentation/screen/todo_screen.dart';
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
        final mainScreens = {
          Routes.homeScreen.toPath,
          Routes.todoScreen.toPath,
          Routes.chatScreen.toPath,
          Routes.creditsScreen.toPath,
          Routes.blogCreen.toPath,
          Routes.calculatorScreen.toPath,
        };
        if (mainScreens.contains(here)) {
          return null;
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
                path: Routes.blogCreen.toPath,
                name: Routes.blogCreen.toName,
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
