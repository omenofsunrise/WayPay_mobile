import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/network/dio_client.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/search/search_destinations.dart';
import 'package:waypay_mobile/core/widgets/search/search_suggester.dart';
import 'package:waypay_mobile/features/home/domain/repositories/home_repository_impl.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/add_button.dart';
import 'package:waypay_mobile/core/widgets/buttons/more_info_button.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/dashboard_card.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/section_title.dart';
import 'package:waypay_mobile/features/home/data/models/employee_model.dart';
import 'package:waypay_mobile/features/home/domain/usecases/get_employee_data_usecase.dart';
import 'package:waypay_mobile/features/home/data/data_source/home_remote_data_source_impl.dart';
import 'package:waypay_mobile/routes/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(AppColors.darkGrey), size: 24),
      title: Text(
        text,
        style: AppStyle.manrope(
          size: 16,
          weight: FontWeight.w500,
          color: const Color(AppColors.black),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<EmployeeModel> _employeeDataFuture;
  late GetEmployeeDataUseCase _getEmployeeDataUseCase;
  late final List<SearchDestination> _destinations;

  @override
  void initState() {
    super.initState();
    final dio = createDio();
    _getEmployeeDataUseCase = GetEmployeeDataUseCase(
      HomeRepositoryImpl(HomeRemoteDataSourceImpl(dio)),
    );
    _destinations = getDefaultSearchDestinations();
    _loadEmployeeData();
  }

  void _loadEmployeeData() {
    setState(() {
      _employeeDataFuture = _getEmployeeDataUseCase();
    });
  }

  void _openAddBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 12,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Header(
                      title: 'Быстрое добавление',
                      showAvatar: false,
                      showBackButton: false,
                      showNotifications: false,
                      trailing: IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: Colors.black54),
                      ),
                    ),
                  ),

                  _AddRow(
                    icon: Icons.person_add_alt,
                    text: 'Добавить клиента',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.pushNamed(Routes.clientCreateScreen.toName);
                    },
                  ),
                  _AddRow(
                    icon: Icons.description_outlined,
                    text: 'Добавить договор',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.pushNamed(Routes.newCreditDetailsScreen.toName);
                    },
                  ),
                  _AddRow(
                    icon: Icons.schedule,
                    text: 'Добавить платёж',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.pushNamed(Routes.scheduleScreen.toName);
                    },
                  ),
                  _AddRow(
                    icon: Icons.trending_up,
                    text: 'Добавить инвестора',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.pushNamed(Routes.investorsScreen.toName);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(num? value) {
    if (value == null) return '0 ₽';
    return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} ₽';
  }

  String _formatCount(int? value) {
    if (value == null) return '0';
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  String _getFullName(EmployeeModel data) {
    return data.fullname ?? 'Пользователь';
  }

  String? _getAvatar(EmployeeModel data) {
    return data.avatar?.isNotEmpty == true ? data.avatar : null;
  }

  String _getCurrentMonth() {
    final months = [
      'январь',
      'февраль',
      'март',
      'апрель',
      'май',
      'июнь',
      'июль',
      'август',
      'сентябрь',
      'октябрь',
      'ноябрь',
      'декабрь',
    ];
    return months[DateTime.now().month - 1];
  }

  bool _canSeeInvestorsSection() {
    final userRole = UserStorage().getRoleSync();
    return userRole == EmployeeRole.superAdmin ||
        userRole == EmployeeRole.admin ||
        userRole == EmployeeRole.director;
  }

  bool _canSeeAnalyticsSection() {
    final userRole = UserStorage().getRoleSync();
    final userPermissions = UserStorage().getPermissionsSync();

    return userRole == EmployeeRole.superAdmin ||
        userRole == EmployeeRole.director ||
        userPermissions.any(
          (permission) => permission == Permission.viewAnalytic,
        );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = UserStorage().getRoleSync();
    final userPermissions = UserStorage().getPermissionsSync();
    final canManageAccounting =
        userPermissions.contains(Permission.manageAccounting) ||
        userRole == EmployeeRole.superAdmin ||
        userRole == EmployeeRole.director;

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<EmployeeModel>(
            future: _employeeDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ошибка загрузки данных',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEmployeeData,
                        child: Text('Повторить'),
                      ),
                    ],
                  ),
                );
              }

              final employeeData = snapshot.data!;

              return CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Header(
                      fullName: _getFullName(employeeData),
                      photoPath: _getAvatar(employeeData),
                      showBackButton: false,
                      trailing: AddButton(onPressed: _openAddBottomSheet),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchSuggester(destinations: _destinations),
                        ),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 13)),

                  _buildCompaniesSection(employeeData),
                  const SliverToBoxAdapter(child: SizedBox(height: 13)),

                  if (_canSeeAnalyticsSection())
                    _buildAnalyticsSection(employeeData),
                  if (_canSeeAnalyticsSection())
                    const SliverToBoxAdapter(child: SizedBox(height: 13)),

                  if (canManageAccounting) _buildFinanceSection(employeeData),
                  if (canManageAccounting)
                    const SliverToBoxAdapter(child: SizedBox(height: 13)),

                  _buildPaymentsSection(employeeData),
                  const SliverToBoxAdapter(child: SizedBox(height: 13)),

                  _buildCreditsSection(employeeData),
                  const SliverToBoxAdapter(child: SizedBox(height: 13)),

                  _buildClientsSection(employeeData),
                  const SliverToBoxAdapter(child: SizedBox(height: 13)),

                  if (_canSeeInvestorsSection())
                    _buildInvestorsSection(employeeData),
                  if (_canSeeInvestorsSection())
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompaniesSection(EmployeeModel data) {
    final userRole = UserStorage().getRoleSync();

    if (userRole != EmployeeRole.superAdmin) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionTitle(text: 'Компании'),
              const Spacer(),
              MoreDetailsButton(
                onPressed: () {
                  // Навигация к компаниям
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'Активные',
                  value: _formatCount(data.activeCompaniesCount),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: DashboardCard(
                  title: 'Всего',
                  value: _formatCount(data.companiesCount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceSection(EmployeeModel data) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionTitle(text: 'Финансы'),
              const Spacer(),
              MoreDetailsButton(
                onPressed: () => context.pushNamed(Routes.financeScreen.toName),
              ),
            ],
          ),
          DashboardCard(
            title: 'Бюджет',
            value: _formatCurrency(
              (data.budgetIncome ?? 0) - (data.budgetOutcome ?? 0),
            ),
            description: _getCurrentMonth(),
          ),
          Row(
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'Приходы бюджета',
                  value: _formatCurrency(data.budgetIncome),
                  description: _getCurrentMonth(),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: DashboardCard(
                  title: 'Расходы бюджета',
                  value: _formatCurrency(data.budgetOutcome),
                  valueColor: const Color(AppColors.red),
                  description: _getCurrentMonth(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection(EmployeeModel data) {
    final approvedCount = data.approvedPaymentsAmount != null
        ? (data.approvedPaymentsAmount! > 1000
              ? data.approvedPaymentsAmount! ~/ 1000
              : 0)
        : 0;

    final disapprovedCount = data.disapprovePaymentsAmount != null
        ? (data.disapprovePaymentsAmount! > 1000
              ? data.disapprovePaymentsAmount! ~/ 1000
              : 0)
        : 0;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionTitle(text: 'Платежи'),
              const Spacer(),
              MoreDetailsButton(
                onPressed: () {
                  context.pushNamed(Routes.paymentScreen.toName);
                },
              ),
            ],
          ),
          DashboardCard(
            title: 'Подтверждённые платежи',
            value: _formatCurrency(data.approvedPaymentsAmount),
            additionalValue: '${_formatCount(approvedCount)} шт',
          ),
          DashboardCard(
            title: 'Неподтверждённые платежи',
            value: _formatCurrency(data.disapprovePaymentsAmount),
            additionalValue: '${_formatCount(disapprovedCount)} шт',
            valueColor: const Color(AppColors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsSection(EmployeeModel data) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionTitle(text: 'Договоры'),
              const Spacer(),
              MoreDetailsButton(
                onPressed: () {
                  context.pushNamed(Routes.creditsScreen.toName);
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'Закрытые',
                  value: _formatCount(data.closedCreditsCount),
                  description: _getCurrentMonth(),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: DashboardCard(
                  title: 'Активные',
                  value: _formatCount(data.activeCreditsCount),
                  description: _getCurrentMonth(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientsSection(EmployeeModel data) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionTitle(text: 'Клиенты'),
              const Spacer(),
              MoreDetailsButton(
                onPressed: () {
                  context.pushNamed(Routes.mainClientScreen.toName);
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'Всего',
                  value: _formatCount(data.clientsCount),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: DashboardCard(
                  title: 'Заявки',
                  value: _formatCount(data.creditApplicationCount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorsSection(EmployeeModel data) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionTitle(text: 'Инвесторы'),
              const Spacer(),
              MoreDetailsButton(
                onPressed: () {
                  context.pushNamed(Routes.investorsHubScreen.toName);
                },
              ),
            ],
          ),
          DashboardCard(title: 'Касса', value: _formatCurrency(data.balance)),
          DashboardCard(
            title: 'Сумма инвестиций',
            value: _formatCurrency(data.investment),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(EmployeeModel data) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionTitle(text: 'Аналитика'),
              const Spacer(),
              MoreDetailsButton(
                onPressed: () =>
                    context.pushNamed(Routes.analyticsScreen.toName),
              ),
            ],
          ),
          DashboardCard(
            title: 'Текущий доход',
            value: _formatCurrency(data.currentIncome),
          ),
          DashboardCard(
            title: 'Ожидаемый доход',
            value: _formatCurrency(data.expectedIncome),
          ),
        ],
      ),
    );
  }
}
