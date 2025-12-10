import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/features/profile/presentation/cubit/profile_cubit.dart'
    show ProfileCubit;
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
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    currentUser = await getCurrentUser(dataSource);
    if (mounted) setState(() {});
  }

  void _openEditProfile() {
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: _profileCubit,
        child: EditProfileModal(currentUser: currentUser!),
      ),
    );
  }

  @override
  void dispose() {
    _profileCubit.close();
    super.dispose();
  }

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
              Header(
                title: 'Профиль',
                showBackButton: true,
                showNotifications: false,
                trailing: const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocProvider.value(
                  value: _profileCubit,
                  child: MyProfileScreen(
                    employeeId: widget.employeeId,
                    refresh: () {},
                    onLogout: _logout,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
