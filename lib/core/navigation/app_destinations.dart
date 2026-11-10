import 'package:waypay_mobile/routes/routes.dart';

class AppDestination {
  const AppDestination({required this.title, required this.route});

  final String title;
  final Routes route;
}

const appDestinations = <AppDestination>[
  AppDestination(title: 'Договоры', route: Routes.creditsScreen),
  AppDestination(title: 'История платежей', route: Routes.paymentHistoryScreen),
  AppDestination(title: 'Очередь клиентов', route: Routes.queueListScreen),
  AppDestination(title: 'Все клиенты', route: Routes.clientListScreen),
  AppDestination(
    title: 'Заявки клиентов',
    route: Routes.clientApplicationsScreen,
  ),
  AppDestination(title: 'Финансы', route: Routes.financeScreen),
  AppDestination(title: 'Инвесторы', route: Routes.investorsScreen),
  AppDestination(title: 'Пул инвесторов', route: Routes.investorPoolScreen),
  AppDestination(title: 'Платежи', route: Routes.paymentScreen),
  AppDestination(title: 'Черный список', route: Routes.blacklistScreen),
  AppDestination(title: 'ЧС+', route: Routes.blacklistPlusScreen),
  AppDestination(title: 'Аналитика', route: Routes.analyticsScreen),
];
