import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/network/dio_client.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/features/home/data/data_source/home_remote_data_source_impl.dart';
import 'package:waypay_mobile/features/home/data/models/employee_model.dart';
import 'package:waypay_mobile/features/home/domain/repositories/home_repository_impl.dart';
import 'package:waypay_mobile/features/home/domain/usecases/get_employee_data_usecase.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/main_client_card.dart';
import 'package:waypay_mobile/routes/routes.dart';
import 'package:waypay_styles/waypay_styles.dart';

class MainClientScreen extends StatefulWidget {
  const MainClientScreen({super.key});

  @override
  State<MainClientScreen> createState() => _MainClientScreenState();
}

class _MainClientScreenState extends State<MainClientScreen> {
  late Future<EmployeeModel> _employeeDataFuture;
  late GetEmployeeDataUseCase _getEmployeeDataUseCase;

  @override
  void initState() {
    super.initState();
    final dio = createDio();
    _getEmployeeDataUseCase = GetEmployeeDataUseCase(
      HomeRepositoryImpl(HomeRemoteDataSourceImpl(dio)),
    );
    _loadEmployeeData();
  }

  void _loadEmployeeData() {
    setState(() {
      _employeeDataFuture = _getEmployeeDataUseCase();
    });
  }

  String _formatCount(int? value) {
    if (value == null) return '0';
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
  }

  String _getFullName(EmployeeModel data) => data.fullname ?? 'Пользователь';

  String? _getAvatar(EmployeeModel data) {
    final avatar = data.avatar;
    if (avatar == null || avatar.isEmpty) return null;
    return avatar;
  }

  @override
  Widget build(BuildContext context) {
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
                      const Text(
                        'Ошибка загрузки данных',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEmployeeData,
                        child: const Text('Повторить'),
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
                      title: 'Клиенты',
                      fullName: _getFullName(employeeData),
                      photoPath: _getAvatar(employeeData),
                      showBackButton: true,
                      showNotifications: false,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: MainClientCard(
                      icon: Icons.people_alt_outlined,
                      title: 'Всего клиентов',
                      value: _formatCount(employeeData.clientsCount),
                      onTap: () =>
                          context.pushNamed(Routes.clientListScreen.toName),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MainClientCard(
                      icon: Icons.assignment_outlined,
                      title: 'Заявки',
                      value: _formatCount(employeeData.creditApplicationCount),
                      onTap: () => context.pushNamed(
                        Routes.clientApplicationsScreen.toName,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MainClientCard(
                      icon: Icons.block_outlined,
                      title: 'Черный список',
                      value: _formatCount(employeeData.blacklistCount),
                      onTap: () =>
                          context.pushNamed(Routes.blacklistScreen.toName),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
