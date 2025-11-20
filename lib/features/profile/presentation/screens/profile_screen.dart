import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/features/profile/presentation/cubit/profile_cubit.dart'
    show ProfileCubit, ProfileLoaded, ProfileState;
import 'package:waypay_mobile/features/profile/presentation/screens/active_sessions_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/company_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/employees_screen.dart';
import 'package:waypay_mobile/features/profile/presentation/screens/my_profile.dart';
import 'package:waypay_mobile/features/profile/presentation/widgets/edit_profile_modal.dart';
import 'package:waypay_mobile/routes/routes.dart';

class ProfileScreen extends StatefulWidget {
  final int? employeeId;
  const ProfileScreen({super.key, this.employeeId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthRemoteDataSource dataSource = getIt<AuthRemoteDataSource>();
  Employee? currentUser;
  final _tokenStorage = TokenStorage();
  final _userStorage = UserStorage();
  int _selectedIndex = 0;

  late List<ProfileTabItem> _tabItems;
  late final ProfileCubit _profileCubit;

  final Map<EmployeeRole, int> roleHierarchy = {
    EmployeeRole.employee: 0,
    EmployeeRole.accountant: 1,
    EmployeeRole.admin: 2,
    EmployeeRole.director: 3,
    EmployeeRole.superAdmin: 4,
  };

  Future<Employee?> getCurrentUser(AuthRemoteDataSource dataSource) async {
    final info = await dataSource.getAuthInfo();
    final employeeJson = info['employee'] as Map<String, dynamic>?;
    if (employeeJson == null) return null;
    return Employee.fromJson(employeeJson);
  }

  bool canEditEmployee({
    required Employee currentUser,
    required Employee targetEmployee,
  }) {
    final currentUserLevel = roleHierarchy[currentUser.role] ?? 0;
    final targetUserLevel = roleHierarchy[targetEmployee.role] ?? 0;
    return (currentUserLevel > targetUserLevel) ||
        (currentUser.id == targetEmployee.id);
  }

  @override
  void initState() {
    super.initState();
    _profileCubit = ProfileCubit();
    if (widget.employeeId == null) {
      _profileCubit.loadProfile();
    } else {
      _profileCubit.loadProfileById(widget.employeeId!);
    }
    loadTabs();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    currentUser = await getCurrentUser(dataSource);
    if (mounted) setState(() {});
  }

  void loadTabs() {
    setState(() {
      _tabItems = [
        ProfileTabItem(
          title: 'Мой профиль',
          content: BlocProvider.value(
            value: _profileCubit,
            child: MyProfileScreen(
              employeeId: widget.employeeId,
              refresh: loadTabs,
            ),
          ),
        ),
      ];

      if (_userStorage.hasViewContent([
        EmployeeRole.superAdmin,
        EmployeeRole.director,
        EmployeeRole.admin,
      ])) {
        _tabItems.add(
          ProfileTabItem(
            title: 'Активные сессии',
            content: ActiveSessionsScreen(),
          ),
        );
      }

      if (_userStorage.hasViewContent([
        EmployeeRole.superAdmin,
        EmployeeRole.director,
        EmployeeRole.admin,
      ])) {
        _tabItems.add(
          ProfileTabItem(title: 'Все пользователи', content: EmployeesScreen()),
        );
      }

      if (_userStorage.hasViewContent([
        EmployeeRole.superAdmin,
        EmployeeRole.director,
      ])) {
        _tabItems.add(
          ProfileTabItem(title: 'О компании', content: CompanyScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _profileCubit.close();
    super.dispose();
  }

  Widget _buildTabItem(int index) {
    final bool isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(AppColors.tabSelected)
              : Color(AppColors.greyLight),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _tabItems[index].title,
          style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
        ),
      ),
    );
  }

  Widget _buildTabContent(int index) => _tabItems[index].content;

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (!mounted) return;
    context.pushReplacementNamed(Routes.phoneAuthScreen.toName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              BlocBuilder<ProfileCubit, ProfileState>(
                bloc: _profileCubit,
                builder: (context, state) {
                  if (state is ProfileLoaded && state.myProfile) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          _tabItems.length,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _buildTabItem(index),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildTabContent(_selectedIndex)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) return;
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: const Icon(Icons.menu, color: Color(AppColors.black)),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Профиль',
            style: AppStyle.semiBold23.copyWith(
              color: const Color(AppColors.black),
            ),
          ),
        ),
        if (_selectedIndex == 0)
          BlocBuilder<ProfileCubit, ProfileState>(
            bloc: _profileCubit,
            builder: (context, state) {
              if (state is ProfileLoaded && currentUser != null) {
                final editable = canEditEmployee(
                  currentUser: currentUser!,
                  targetEmployee: state.employee,
                );
                if (editable) {
                  return IconButton(
                    icon: const Icon(Icons.edit, color: Color(AppColors.black)),
                    tooltip: 'Редактировать',
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => BlocProvider.value(
                          value: _profileCubit,
                          child: EditProfileModal(currentUser: currentUser!),
                        ),
                      );
                      if (widget.employeeId == null) {
                        _profileCubit.loadProfile();
                      } else {
                        _profileCubit.loadProfileById(widget.employeeId!);
                      }
                    },
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.logout, color: Color(AppColors.black)),
          tooltip: 'Выйти',
          onPressed: _logout,
        ),
      ],
    );
  }
}

class ProfileTabItem {
  final String title;
  final Widget content;
  ProfileTabItem({required this.title, required this.content});
}
