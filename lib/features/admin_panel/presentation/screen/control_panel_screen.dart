import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';

class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> {
  final _storage = UserStorage();

  late bool _notifications;
  late bool _creditName;
  late bool _catalog;
  late bool _category;

  @override
  void initState() {
    super.initState();
    _notifications = _storage.showNotifications;
    _creditName = _storage.showCreditName;
    _catalog = _storage.showCreditCatalog;
    _category = _storage.showCreditCategory;
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notifications = value);
    await _storage.saveInterfaceVisibility(showNotifications: value);
  }

  Future<void> _setCreditName(bool value) async {
    setState(() => _creditName = value);
    await _storage.saveInterfaceVisibility(showCreditName: value);
  }

  Future<void> _setCatalog(bool value) async {
    setState(() => _catalog = value);
    await _storage.saveInterfaceVisibility(showCreditCatalog: value);
  }

  Future<void> _setCategory(bool value) async {
    setState(() => _category = value);
    await _storage.saveInterfaceVisibility(showCreditCategory: value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'Настройка интерфейса',
                showBackButton: true,
                showNotifications: false,
                showAvatar: false,
              ),
              const SizedBox(height: 20),
              const Text(
                'Главный экран',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _VisibilityTile(
                title: 'Уведомления',
                subtitle: 'Показывать колокольчик на главном экране',
                value: _notifications,
                onChanged: _setNotifications,
              ),
              const SizedBox(height: 22),
              const Text(
                'Новый договор',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _VisibilityTile(
                title: 'Название договора',
                subtitle: 'Показывать поле названия договора',
                value: _creditName,
                onChanged: _setCreditName,
              ),
              const SizedBox(height: 10),
              _VisibilityTile(
                title: 'Каталог',
                subtitle: 'Показывать выбор каталога',
                value: _catalog,
                onChanged: _setCatalog,
              ),
              const SizedBox(height: 10),
              _VisibilityTile(
                title: 'Категория',
                subtitle: 'Показывать выбор категории',
                value: _category,
                onChanged: _setCategory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityTile extends StatelessWidget {
  const _VisibilityTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(AppColors.primary),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
