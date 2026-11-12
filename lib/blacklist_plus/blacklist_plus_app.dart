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
        theme: WayPayTheme.light,
      ),
    );
  }
}

Widget _appTextScaleBuilder(BuildContext context, Widget? child) {
  final mediaQuery = MediaQuery.of(context);
  return MediaQuery(
    data: mediaQuery.copyWith(textScaler: const TextScaler.linear(0.94)),
    child: child ?? const SizedBox.shrink(),
  );
}
