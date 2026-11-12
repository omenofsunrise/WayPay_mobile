import 'package:waypay_mobile/blacklist_plus/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/app_mode/app_mode.dart';
import 'package:waypay_mobile/blacklist_plus/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/widgets/profile_black_catalog.dart';
import 'package:waypay_mobile/blacklist_plus/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class ProfileScreen extends StatefulWidget {
  final int? employeeId;

  const ProfileScreen({super.key, this.employeeId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRemoteDataSource _authDataSource = getIt<AuthRemoteDataSource>();

  bool _loading = true;
  bool _loggingOut = false;
  String _name = '';
  String _phone = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _authDataSource.getSessionInfo();
      if (!mounted) return;

      final clientRaw = session?['client'];
      final client = clientRaw is Map
          ? Map<String, dynamic>.from(clientRaw)
          : null;

      setState(() {
        _name = (client?['name'] as String?)?.trim().isNotEmpty == true
            ? client!['name'] as String
            : 'Пользователь';
        _phone = (client?['phone'] as String?) ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _name = 'Пользователь';
        _phone = '';
        _loading = false;
        _error = 'Не удалось загрузить данные пользователя';
      });
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _loggingOut = true);
    try {
      await _authDataSource.logout();
    } catch (_) {
    } finally {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      context.goNamed(Routes.phoneAuthScreen.toName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Header(
                title: 'Профиль',
                showNotifications: false,
                showAvatar: false,
              ),
            ),
            Expanded(
              child: _loading
                  ? const WayPayLoadingState()
                  : RefreshIndicator(
                      onRefresh: _loadUserData,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (_error != null) ...[
                            WayPayErrorState(message: _error),
                            const SizedBox(height: 12),
                          ],
                          _ProfileCard(
                            name: _name,
                            phone: _phone,
                            isLoggingOut: _loggingOut,
                            onLogout: _loggingOut ? null : _handleLogout,
                          ),
                          const SizedBox(height: 12),
                          _NavTile(
                            icon: Icons.swap_horiz_rounded,
                            title: 'Перейти в WayPay',
                            subtitle: 'Вернуться в основную программу',
                            onTap: () => AppModeController.instance.switchTo(
                              AppMode.waypay,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _NavTile(
                            icon: Icons.bar_chart_rounded,
                            title: 'Статистика и долги',
                            subtitle: 'Активность и локальный журнал долгов',
                            onTap: () =>
                                context.goNamed(Routes.statsScreen.toName),
                          ),
                          const SizedBox(height: 12),
                          _NavTile(
                            icon: Icons.description_outlined,
                            title: 'Шаблоны документов',
                            subtitle: 'Расписки, акты и уведомления',
                            onTap: () =>
                                context.goNamed(Routes.templatesScreen.toName),
                          ),
                          const SizedBox(height: 24),
                          const ProfileBlackCatalog(
                            allowEdit: true,
                            pageSize: 10,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String phone;
  final bool isLoggingOut;
  final VoidCallback? onLogout;

  const _ProfileCard({
    required this.name,
    required this.phone,
    required this.isLoggingOut,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return WayPaySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WayPayEntityTile(
            title: name,
            subtitle: phone.isEmpty ? 'Телефон не указан' : phone,
            padding: EdgeInsets.zero,
            leading: const WayPayIconBadge(icon: Icons.person_outline),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: DefaultButton(
              text: isLoggingOut ? 'Выход...' : 'Выйти из аккаунта',
              color: const Color(AppColors.red),
              onPressed: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return WayPayEntityCard(
      title: title,
      subtitle: subtitle,
      leading: WayPayIconBadge(icon: icon),
      onTap: onTap,
    );
  }
}
