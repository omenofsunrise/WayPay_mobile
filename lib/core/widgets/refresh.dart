import 'package:flutter/material.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay/core/models/employee_role.dart';
import 'package:waypay/core/storage/user_storage.dart';

class Refresher extends StatelessWidget {
  final Widget content;
  final Future<void> Function() onRefresh;

  const Refresher({super.key, required this.content, required this.onRefresh});

  Future<void> _updateUserRole() async {
    debugPrint("🔄 Обновление роли...");
    final authDataSource = getIt<AuthRemoteDataSource>();
    final userStorage = UserStorage();

    try {
      final info = await authDataSource.getAuthInfo();
      final employee = info['employee'] as Map<String, dynamic>?;

      if (employee == null) {
        debugPrint('⚠️ Нет данных о пользователе');
        return;
      }

      final roleStr = employee['role']?.toString() ?? '';
      final role = EmployeeRoleMapper.fromApi(roleStr);
      await userStorage.saveRole(role);

      final permissionsList = (employee['permissions'] as List?) ?? [];
      final permissions = permissionsList
          .map((p) => PermissionMapper.fromApi(p.toString()))
          .toList();
      await userStorage.savePermissions(permissions);

      debugPrint('✅ Роль обновлена: $role, права: $permissions');
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении роли: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await _updateUserRole();
    await onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _handleRefresh, child: content);
  }
}
