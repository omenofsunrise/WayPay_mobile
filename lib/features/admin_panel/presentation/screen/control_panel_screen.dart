import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/info/screens/info_screen.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/routes/routes.dart';

class ControlPanelScreen extends StatelessWidget {
  const ControlPanelScreen({super.key});

  bool _hasExtendedAccess(EmployeeRole? role) {
    return role == EmployeeRole.director || role == EmployeeRole.superAdmin;
  }

  Future<void> _openWebSettings(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse('https://web.waypay.one/settings'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showAppMessage(
        context,
        'Не удалось открыть веб-панель',
        type: AppMessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = UserStorage().getRoleSync();
    final extended = _hasExtendedAccess(role);
    final items = <_ControlPanelItem>[
      _ControlPanelItem(
        icon: Icons.tune_outlined,
        title: 'Настройка интерфейса',
        subtitle: 'Скрытие неиспользуемых разделов',
        onTap: () => context.pushNamed(Routes.interfaceSettingsScreen.toName),
      ),
      _ControlPanelItem(
        icon: Icons.people_outline,
        title: 'Сотрудники',
        subtitle: 'Сотрудники и их доступы',
        onTap: () => context.pushNamed(Routes.profileEmployeesScreen.toName),
      ),
      if (extended)
        _ControlPanelItem(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Роли',
          subtitle: 'Роли и права сотрудников',
          opensWeb: true,
          onTap: () => _openWebSettings(context),
        ),
      if (extended)
        _ControlPanelItem(
          icon: Icons.business_outlined,
          title: 'Данные компании',
          subtitle: 'Реквизиты и основные настройки',
          onTap: () => context.pushNamed(Routes.companyDataScreen.toName),
        ),
      if (extended)
        _ControlPanelItem(
          icon: Icons.campaign_outlined,
          title: 'Рассылка',
          subtitle: 'Шаблоны и события рассылок',
          opensWeb: true,
          onTap: () => _openWebSettings(context),
        ),
      _ControlPanelItem(
        icon: Icons.chat_outlined,
        title: 'WhatsApp',
        subtitle: 'Каналы, номера и боты',
        opensWeb: true,
        onTap: () => _openWebSettings(context),
      ),
      if (extended)
        _ControlPanelItem(
          icon: Icons.history_outlined,
          title: 'Журнал действий',
          subtitle: 'История изменений сотрудников',
          opensWeb: true,
          onTap: () => _openWebSettings(context),
        ),
      if (extended)
        _ControlPanelItem(
          icon: Icons.description_outlined,
          title: 'Отчёты',
          subtitle: 'Автоматические Excel-отчёты',
          opensWeb: true,
          onTap: () => _openWebSettings(context),
        ),
      _ControlPanelItem(
        icon: Icons.info_outline,
        title: 'О программе',
        subtitle: 'Версия, лицензия и контакты',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InfoScreen()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'Панель управления',
                showBackButton: true,
                showNotifications: false,
                showAvatar: false,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) =>
                      _ControlPanelCard(item: items[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlPanelItem {
  const _ControlPanelItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.opensWeb = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool opensWeb;
}

class _ControlPanelCard extends StatelessWidget {
  const _ControlPanelCard({required this.item});

  final _ControlPanelItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F5F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: const Color(AppColors.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (item.opensWeb) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.open_in_new,
                            size: 14,
                            color: Color(AppColors.uiBorder),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(AppColors.uiBorder),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(AppColors.uiBorder)),
            ],
          ),
        ),
      ),
    );
  }
}
