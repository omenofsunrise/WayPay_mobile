import 'package:flutter/material.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay/core/models/employee_role.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _employee;
  EmployeeRole? _role;
  List<Permission> _permissions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      final info = await authDataSource.getAuthInfo();
      final employee = info['employee'] as Map<String, dynamic>?;

      if (employee == null) {
        setState(() {
          _error = 'Данные пользователя не найдены';
          _loading = false;
        });
        return;
      }

      final roleStr = employee['role']?.toString() ?? '';
      final role = EmployeeRoleMapper.fromApi(roleStr);

      final permissionsList = (employee['permissions'] as List?) ?? [];
      final permissions = permissionsList
          .map((p) => PermissionMapper.fromApi(p.toString()))
          .toList();

      print('✅ Роль в экране: $role');
      print('✅ Права: $permissions');

      setState(() {
        _employee = employee;
        _role = role;
        _permissions = permissions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки профиля: $e';
        _loading = false;
      });
    }
  }

  String _roleLabel(EmployeeRole? role) {
    if (role == null) return 'Неизвестно';
    switch (role) {
      case EmployeeRole.accountant:
        return 'Бухгалтер';
      case EmployeeRole.employee:
        return 'Сотрудник';
      case EmployeeRole.admin:
        return 'Администратор';
      case EmployeeRole.superAdmin:
        return 'Суперадминистратор';
      case EmployeeRole.director:
        return 'Директор';
    }
  }

  String _permissionLabel(Permission p) {
    switch (p) {
      case Permission.createCredits:
        return 'Создание кредитов';
      case Permission.deleteCredits:
        return 'Удаление кредитов';
    }
  }

  String? _resolvePhotoUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return 'https://web.waypay.one:5001$path';
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    return parts.map((p) => p[0].toUpperCase()).take(2).join();
  }

  Color _stringToColor(String str) {
    int hash = 0;
    for (var i = 0; i < str.length; i++) {
      hash = str.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final hue = hash % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.6).toColor();
  }

  Widget _buildAvatar(String? photoPath, String? name) {
    final resolvedUrl = _resolvePhotoUrl(photoPath);
    if (resolvedUrl != null) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(resolvedUrl),
      );
    }
    final initials = _getInitials(name);
    final color = _stringToColor(initials);
    return CircleAvatar(
      radius: 40,
      backgroundColor: color,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:')),
          Expanded(child: Text(value ?? '—')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _employee == null
          ? const Center(child: Text('Нет данных о пользователе'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: _buildAvatar(
                      _employee!['photoPath'],
                      _employee!['fullName'],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('ID', _employee!['id']?.toString()),
                  _buildInfoRow('ФИО', _employee!['fullName']),
                  _buildInfoRow('Телефон', _employee!['phone']),
                  _buildInfoRow('Адрес', _employee!['address']),
                  _buildInfoRow('Роль', _roleLabel(_role)),
                  _buildInfoRow(
                    'Мин. надбавка',
                    _employee!['minSurcharge']?.toString(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Права:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (_permissions.isEmpty)
                    const Text('Нет прав')
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _permissions
                          .map((p) => Text('- ${_permissionLabel(p)}'))
                          .toList(),
                    ),
                ],
              ),
            ),
    );
  }
}
