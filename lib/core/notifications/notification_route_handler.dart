import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_modal.dart';
import 'package:waypay_mobile/routes/app_router.dart';
import 'package:waypay_mobile/routes/routes.dart';

class NotificationRouteHandler {
  const NotificationRouteHandler._();

  static Future<void> open(String? rawRoute) async {
    final value = rawRoute?.trim();
    if (value == null || value.isEmpty) return;

    final external = Uri.tryParse(value);
    if (external != null &&
        (external.scheme == 'http' || external.scheme == 'https')) {
      await launchUrl(external, mode: LaunchMode.externalApplication);
      return;
    }

    final route = value.replaceFirst(RegExp(r'^/+'), '');
    final creditMatch = RegExp(r'^credits/(\d+)$').firstMatch(route);
    if (creditMatch != null) {
      await _openCredit(int.parse(creditMatch.group(1)!));
      return;
    }
    if (route == 'credits/in-debt') {
      AppRouter.router.go('${Routes.creditsScreen.toPath}?tab=debtors');
      return;
    }
    if (route == 'finance') {
      AppRouter.router.go(Routes.financeScreen.toPath);
      return;
    }

    final whatsAppMatch = RegExp(r'^admin/whatsapp/(.+)$').firstMatch(route);
    if (whatsAppMatch != null) {
      final phone = whatsAppMatch.group(1)!.replaceAll(RegExp(r'\D'), '');
      if (phone.isNotEmpty) {
        await launchUrl(
          Uri.parse('https://wa.me/$phone'),
          mode: LaunchMode.externalApplication,
        );
      }
      return;
    }

    await launchUrl(
      Uri.parse('https://web.waypay.one/$route'),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> _openCredit(int id) async {
    try {
      final credit = await getIt<CreditRemoteDataSource>().getCreditById(id);
      final context = AppRouter.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => CreditFullScreen(credit: credit, isControl: false),
        ),
      );
    } catch (error) {
      debugPrint('Не удалось открыть договор из уведомления: $error');
      AppRouter.router.go(Routes.creditsScreen.toPath);
    }
  }
}
