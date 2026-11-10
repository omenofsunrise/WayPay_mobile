import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/blacklist_plus/core/di/dependency_injection.dart';
import 'package:waypay_mobile/blacklist_plus/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:waypay_mobile/blacklist_plus/routes/app_router.dart';

/// Приложение «ЧС+»: свой роутер, своя тема, свои зависимости и вход.
class BlacklistPlusApp extends StatelessWidget {
  const BlacklistPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => getIt<ProfileCubit>())],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'ЧС+',
        builder: _appTextScaleBuilder,
        routerConfig: AppRouter.router,
        theme: _theme,
      ),
    );
  }

  static final ThemeData _theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      iconTheme: IconThemeData(color: Colors.black),
      backgroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _border,
      enabledBorder: _border,
      focusedBorder: _border,
      errorBorder: _border,
      focusedErrorBorder: _border,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(shape: _shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: _shape),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: _shape),
    ),
  );

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
  );
  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  );
}

Widget _appTextScaleBuilder(BuildContext context, Widget? child) {
  final mediaQuery = MediaQuery.of(context);
  return MediaQuery(
    data: mediaQuery.copyWith(textScaler: const TextScaler.linear(0.94)),
    child: child ?? const SizedBox.shrink(),
  );
}
