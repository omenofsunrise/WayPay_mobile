import 'package:waypay_mobile/core/widgets/search/search_suggester.dart';
import 'package:waypay_mobile/routes/routes.dart';

List<SearchDestination> getDefaultSearchDestinations() {
  return const [
    SearchDestination(
      title: 'Договоры',
      route: Routes.creditsScreen,
      keywords: ['договор', 'рассрочка', 'credit', 'contract'],
    ),
    SearchDestination(
      title: 'История платежей',
      route: Routes.paymentHistoryScreen,
      keywords: ['история', 'платеж', 'history', 'payments'],
    ),
    SearchDestination(
      title: 'Очередь клиентов',
      route: Routes.queueListScreen,
      keywords: ['очередь', 'queue', 'клиент'],
    ),
    SearchDestination(
      title: 'Все клиенты',
      route: Routes.clientListScreen,
      keywords: ['всего клиентов', 'клиенты', 'clients', 'list'],
    ),
    SearchDestination(
      title: 'Заявки клиентов',
      route: Routes.clientApplicationsScreen,
      keywords: ['очередь заявок', 'заявки', 'applications', 'lead', 'request'],
    ),
    SearchDestination(
      title: 'Финансы',
      route: Routes.financeScreen,
      keywords: ['финансы', 'бюджет', 'касса', 'budget', 'finance'],
    ),
    SearchDestination(
      title: 'Инвесторы',
      route: Routes.investorsScreen,
      keywords: ['инвесторы', 'investor', 'investment'],
    ),
    SearchDestination(
      title: 'Пул инвесторов',
      route: Routes.investorPoolScreen,
      keywords: ['пул', 'investor pool', 'инвесторы пул'],
    ),
    SearchDestination(
      title: 'Платежи',
      route: Routes.paymentScreen,
      keywords: ['платежи', 'payments', 'journal'],
    ),
    SearchDestination(
      title: 'Черный список',
      route: Routes.blacklistScreen,
      keywords: ['черный список', 'blacklist', 'stop', 'ban'],
    ),
    SearchDestination(
      title: 'ЧС+',
      route: Routes.blacklistPlusScreen,
      keywords: ['чс+', 'чс плюс', 'проверка', 'black catalog', 'stop list'],
    ),
    SearchDestination(
      title: 'Аналитика',
      route: Routes.analyticsScreen,
      keywords: ['аналитика', 'статистика', 'отчёты', 'analytics', 'dashboard'],
    ),
  ];
}
