import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/analytics/presentation/screens/analytic_screen.dart';
import 'package:waypay_mobile/features/blog/presentation/screens/blog_screen.dart';
import 'package:waypay_mobile/features/calc/calculator_page.dart';
import 'package:waypay_mobile/features/chat/presentation/screens/all_chat_screen.dart';
import 'package:waypay_mobile/features/credit/presentation/screens/control_credit_screen.dart';
import 'package:waypay_mobile/features/info/screens/info_screen.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/drawer_models.dart';
import 'package:waypay_mobile/features/admin_panel/presentation/screen/admin_panel_screen.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/blacklist/blacklist_bloc.dart';
import 'package:waypay_mobile/features/clients/presentation/screens/blacklist_screen.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/features/clients/presentation/screens/clients_screen.dart';
import 'package:waypay_mobile/features/credit/presentation/screens/credit_screen.dart';
import 'package:waypay_mobile/features/finance/presentation/screens/budget_screen.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investors_hub_screen.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investors_screen.dart';
import 'package:waypay_mobile/features/product/presentation/bloc/products_bloc.dart';
import 'package:waypay_mobile/features/product/presentation/screens/product_screen.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/queue/queue_bloc.dart';
import 'package:waypay_mobile/features/clients/presentation/screens/queue_screen.dart';
import 'package:waypay_mobile/features/todo/data/data_soucres/task_remote_data_source.dart';
import 'package:waypay_mobile/features/todo/presentation/screen/todo_screen.dart';
import 'package:waypay_mobile/routes/routes.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final Map<int, ExpansibleController> _controllers = {};
  final _userStorage = UserStorage();

  ExpansibleController _controllerFor(int index) =>
      _controllers.putIfAbsent(index, () => ExpansibleController());

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
              const SizedBox(height: 60),
              Align(
                alignment: Alignment.center,
                child: SvgPicture.asset(SvgIcons.logo, width: 120, height: 36),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.person,
                        color: Color(AppColors.background),
                        size: 24,
                      ),
                      onTap: () {
                        context.pushNamed(Routes.profileScreen.toName);
                      },
                      title: Text(
                        'Профиль',
                        style: AppStyle.medium16.copyWith(
                          color: const Color(AppColors.background),
                        ),
                      ),
                    ),
                    if (!_userStorage.hasViewContent([
                      EmployeeRole.accountant,
                      EmployeeRole.employee,
                    ]))
                      ListTile(
                        leading: SvgPicture.asset(
                          SvgIcons.analyticsLogo,
                          height: 24,
                          width: 24,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnalyticsScreen(),
                            ),
                          );
                        },
                        title: Text(
                          'Аналитика',
                          style: AppStyle.medium16.copyWith(
                            color: const Color(AppColors.background),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            leading: SvgPicture.asset(
                              SvgIcons.todo,
                              height: 24,
                              width: 24,
                            ),
                            title: Text(
                              'Todo',
                              style: AppStyle.medium16.copyWith(
                                color: const Color(AppColors.background),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TodoScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        FutureBuilder<int>(
                          future: getIt<TaskRemoteDataSource>()
                              .getActiveCountTasks(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 21,
                                width: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            } else if (snapshot.hasError || !snapshot.hasData) {
                              return const SizedBox();
                            } else {
                              final count = snapshot.data!;
                              return count > 0
                                  ? Container(
                                      height: 21,
                                      width: 21,
                                      decoration: BoxDecoration(
                                        color: Color(AppColors.background),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$count',
                                          style: AppStyle.medium16.copyWith(
                                            color: const Color(
                                              AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox();
                            }
                          },
                        ),
                        const SizedBox(width: 30),
                      ],
                    ),
                    ListTile(
                      leading: SvgPicture.asset(
                        SvgIcons.chatLogo,
                        height: 24,
                        width: 24,
                      ),
                      title: Text(
                        'Чат',
                        style: AppStyle.medium16.copyWith(
                          color: const Color(AppColors.background),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllChatScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: SvgPicture.asset(
                        SvgIcons.calculator,
                        height: 24,
                        width: 24,
                      ),
                      title: Text(
                        'Калькулятор',
                        style: AppStyle.medium16.copyWith(
                          color: const Color(AppColors.background),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalculatorScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: SvgPicture.asset(
                        SvgIcons.blogLogo,
                        height: 24,
                        width: 24,
                      ),
                      title: Text(
                        'Лента',
                        style: AppStyle.medium16.copyWith(
                          color: const Color(AppColors.background),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BlogScreen(),
                          ),
                        );
                      },
                    ),
                    if (_userStorage.hasViewContent([EmployeeRole.superAdmin]))
                      ListTile(
                        leading: SvgPicture.asset(
                          SvgIcons.shieldPerson,
                          height: 24,
                          width: 24,
                        ),
                        title: Text(
                          'Админка',
                          style: AppStyle.medium16.copyWith(
                            color: const Color(AppColors.background),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminPanelScreen(),
                            ),
                          );
                        },
                      ),

                    ...List.generate(sections.length, (index) {
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
                          style: AppStyle.medium16.copyWith(
                            color: const Color(AppColors.background),
                          ),
                        ),
                        children: [
                          Container(
                            margin: const EdgeInsets.only(left: 24),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 8,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 1,
                                    color: Colors.white54,
                                  ),
                                ),
                                Column(
                                  children: section.items
                                      .map(
                                        (item) => ListTile(
                                          contentPadding: const EdgeInsets.only(
                                            left: 24,
                                          ),
                                          title: Text(
                                            item.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
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
                    }),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Divider(height: 1, color: Color(AppColors.background)),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: Text(
                  'О программе',
                  style: AppStyle.medium16.copyWith(
                    color: const Color(AppColors.background),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InfoScreen()),
                  );
                },
              ),
              const SizedBox(height: 15),
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
          DrawerItem(
            title: 'Договоры',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreditsScreen()),
              );
            },
          ),
          if (_userStorage.hasViewContent([
            EmployeeRole.superAdmin,
            EmployeeRole.director,
            EmployeeRole.admin,
          ]))
            DrawerItem(
              title: 'Контроль договоров',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ControlCreditsScreen(),
                  ),
                );
              },
            ),
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
                    create: (_) => ClientsBloc()
                      ..add(LoadClients(refresh: true, page: 1, pageSize: 10)),
                    child: const ClientsScreen(),
                  ),
                ),
              );
            },
          ),
          DrawerItem(
            title: 'Очередь',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (_) => QueueBloc()
                      ..add(LoadQueue(refresh: true, page: 1, pageSize: 10)),
                  ),
                ),
              );
            },
          ),
          DrawerItem(
            title: 'Черный список',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (_) => BlacklistBloc()
                      ..add(
                        LoadBlacklistedClients(
                          refresh: true,
                          page: 1,
                          pageSize: 10,
                        ),
                      ),
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
          DrawerItem(
            title: 'Ожидаемые',
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(Routes.scheduleScreen.toName);
            },
          ),
          DrawerItem(
            title: 'Журнал',
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(Routes.paymentScreen.toName);
            },
          ),
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
                MaterialPageRoute(builder: (_) => const InvestorsHubScreen()),
              );
            },
          ),
        ],
      ),
      DrawerSection(
        title: 'Справочник',
        iconAsset: SvgIcons.book,
        items: [
          DrawerItem(
            title: 'Товары',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (_) =>
                        ProductsBloc()..add(LoadProductsEvent(refresh: true)),
                    child: const ProductsScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      if (_userStorage.hasViewContent([
        EmployeeRole.superAdmin,
        EmployeeRole.director,
        EmployeeRole.admin,
      ]))
        DrawerSection(
          title: 'Финансы',
          iconAsset: SvgIcons.book,
          items: [
            DrawerItem(
              title: 'Бюджет',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (_) =>
                          InvestorsBloc()
                            ..add(LoadInvestorsEvent(refresh: true)),
                      child: const BudgetScreen(),
                    ),
                  ),
                );
              },
            ),
            DrawerItem(
              title: 'Доходы по платежам',
              onTap: () {
                Navigator.pop(context);
                context.pushNamed(Routes.paymentIncomeScreen.toName);
              },
            ),
          ],
        ),
    ];
  }
}
