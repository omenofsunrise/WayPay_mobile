import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:waypay/assets/resources.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_drawer/drawer_models.dart';
import 'package:waypay/features/blacklist/presentation/bloc/blacklist_bloc.dart';
import 'package:waypay/features/blacklist/presentation/screen/blacklist_screen.dart';
import 'package:waypay/features/clients/presentation/bloc/clients_bloc.dart';
import 'package:waypay/features/clients/presentation/screens/clients_screen.dart';
import 'package:waypay/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay/features/investors/presentation/screens/investor_report_screen.dart';
import 'package:waypay/features/investors/presentation/screens/investors_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final Map<int, ExpansibleController> _controllers = {};
  final _userStorage = UserStorage();

  ExpansibleController _controllerFor(int index) => _controllers.putIfAbsent(index, () => ExpansibleController());

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _userStorage.roleNotifier,
      builder: (_, role, __) {
        final canAddInvestor = _userStorage.canViewAdminContent();
        final sections = _buildSections(canAddInvestor);

        return Drawer(
          backgroundColor: const Color(AppColors.primary),
          child: Column(
            children: [
              SizedBox(
                height: 130,
                child: DrawerHeader(
                  decoration: const BoxDecoration(color: Color(AppColors.primary)),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Меню',
                      style: AppStyle.inter(
                        size: 24,
                        weight: FontWeight.w600,
                        color: const Color(AppColors.background),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: sections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final controller = _controllerFor(index);

                    return ExpansionTile(
                      controller: controller,
                      onExpansionChanged: (expanded) {
                        if (expanded) {
                          _controllers.forEach((key, otherController) {
                            if (key != index) otherController.collapse();
                          });
                        }
                      },
                      leading: SvgPicture.asset(
                        section.iconAsset,
                        color: const Color(AppColors.background),
                        height: 24,
                        width: 24,
                      ),
                      collapsedIconColor: const Color(AppColors.background),
                      iconColor: const Color(AppColors.background),
                      shape: const Border(),
                      title: Text(
                        section.title,
                        style: AppStyle.medium16.copyWith(color: const Color(AppColors.background)),
                      ),
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 24),
                          child: Stack(
                            children: [
                              Positioned(left: 8, top: 0, bottom: 0, child: Container(width: 1, color: Colors.white54)),
                              Column(
                                children: section.items
                                    .map(
                                      (item) => ListTile(
                                        contentPadding: const EdgeInsets.only(left: 24),
                                        title: Text(item.title, style: const TextStyle(color: Colors.white)),
                                        onTap: item.onTap,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.white),
                title: const Text('Переключиться на клиента', style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  List<DrawerSection> _buildSections(bool canAddInvestor) {
    return [
      DrawerSection(
        title: 'Договоры',
        iconAsset: SvgIcons.notebook,
        items: [
          DrawerItem(title: 'Договоры', onTap: () {}),
          DrawerItem(title: 'Контроль договоров', onTap: () {}),
        ],
      ),
      DrawerSection(
        title: 'Клиенты',
        iconAsset: SvgIcons.users,
        items: [
          DrawerItem(
            title: 'Клиенты',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (_) => ClientsBloc()..add(LoadClients(refresh: true, page: 1, pageSize: 10)),
                    child: const ClientsScreen(),
                  ),
                ),
              );
            },
          ),
          DrawerItem(title: 'Очередь', onTap: () {}),
          DrawerItem(
            title: 'Черный список',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (_) => BlacklistBloc()..add(LoadBlacklistedClients(refresh: true, page: 1, pageSize: 10)),
                    child: const BlacklistScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      DrawerSection(
        title: 'Платежи',
        iconAsset: SvgIcons.fileDigit,
        items: [
          DrawerItem(title: 'Ожидаемые', onTap: () {}),
          DrawerItem(title: 'Журнал', onTap: () {}),
        ],
      ),
      DrawerSection(
        title: 'Инвесторы',
        iconAsset: SvgIcons.moneybag,
        items: [
          DrawerItem(
            title: 'Инвесторы',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (_) => InvestorsBloc()..add(LoadInvestorsEvent(refresh: true)),
                    child: const InvestorsScreen(),
                  ),
                ),
              );
            },
          ),
          if (canAddInvestor)
            DrawerItem(
              title: 'Отчет для инвесторов',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (_) => InvestorsBloc()..add(LoadInvestorsEvent(refresh: true)),
                      child: const InvestorReportScreen(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      DrawerSection(
        title: 'Справочник',
        iconAsset: SvgIcons.book,
        items: [
          DrawerItem(title: 'Товары', onTap: () {}),
          DrawerItem(title: 'Поручители', onTap: () {}),
        ],
      ),
      DrawerSection(
        title: 'Финансы',
        iconAsset: SvgIcons.book,
        items: [
          DrawerItem(title: 'Бюджет', onTap: () {}),
          DrawerItem(title: 'Доходы', onTap: () {}),
          DrawerItem(title: 'Расходы', onTap: () {}),
        ],
      ),
    ];
  }
}
