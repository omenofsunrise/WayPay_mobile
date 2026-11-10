import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';

class UserStorage {
  static final UserStorage _instance = UserStorage._internal();

  factory UserStorage() => _instance;

  UserStorage._internal() {
    _init();
  }

  static const _roleKey = 'user_role';
  static const _permissionsKey = 'user_permissions';
  static const _creditAcceptanceKey = 'company_credit_acceptance';
  static const _paymentAcceptanceKey = 'company_payment_acceptance';
  static const _showCreditNameKey = 'company_show_credit_name';
  static const _showCreditCatalogKey = 'company_show_credit_catalog';
  static const _showCreditCategoryKey = 'company_show_credit_category';
  static const _showNotificationsKey = 'show_notifications';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _showCreditNotificationsKey =
      'show_credit_creation_notifications';
  static const _showWhatsAppNotificationsKey = 'show_whatsapp_notifications';

  final ValueNotifier<EmployeeRole?> roleNotifier =
      ValueNotifier<EmployeeRole?>(null);

  final ValueNotifier<Set<Permission>> permissionsNotifier =
      ValueNotifier<Set<Permission>>({});

  /// Настройки компании «Подтверждение договоров» и «Подтверждение платежей».
  /// Выключены — подтверждать нечего, статусы и счётчики подтверждения не нужны.
  final ValueNotifier<bool> creditAcceptanceNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> paymentAcceptanceNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> showCreditNameNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> showCreditCatalogNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> showCreditCategoryNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> showNotificationsNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> notificationsEnabledNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> showCreditNotificationsNotifier =
      ValueNotifier<bool>(true);
  final ValueNotifier<bool> showWhatsAppNotificationsNotifier =
      ValueNotifier<bool>(true);

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString(_roleKey);
    if (roleStr != null) {
      roleNotifier.value = EmployeeRole.values.firstWhere(
        (r) => r.name == roleStr,
      );
    }
    final perms = prefs.getStringList(_permissionsKey);
    if (perms != null) {
      permissionsNotifier.value = perms
          .map((e) => Permission.values.firstWhere((p) => p.name == e))
          .toSet();
    }
    creditAcceptanceNotifier.value =
        prefs.getBool(_creditAcceptanceKey) ?? true;
    paymentAcceptanceNotifier.value =
        prefs.getBool(_paymentAcceptanceKey) ?? true;
    showCreditNameNotifier.value = prefs.getBool(_showCreditNameKey) ?? true;
    showCreditCatalogNotifier.value =
        prefs.getBool(_showCreditCatalogKey) ?? true;
    showCreditCategoryNotifier.value =
        prefs.getBool(_showCreditCategoryKey) ?? true;
    showNotificationsNotifier.value =
        prefs.getBool(_showNotificationsKey) ?? true;
    notificationsEnabledNotifier.value =
        prefs.getBool(_notificationsEnabledKey) ?? true;
    showCreditNotificationsNotifier.value =
        prefs.getBool(_showCreditNotificationsKey) ?? true;
    showWhatsAppNotificationsNotifier.value =
        prefs.getBool(_showWhatsAppNotificationsKey) ?? true;
  }

  Future<void> saveRole(EmployeeRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
    roleNotifier.value = role;
  }

  EmployeeRole? getRoleSync() {
    return roleNotifier.value;
  }

  Future<void> savePermissions(List<Permission> permissions) async {
    final prefs = await SharedPreferences.getInstance();
    final list = permissions.map((e) => e.name).toList();
    await prefs.setStringList(_permissionsKey, list);
    permissionsNotifier.value = permissions.toSet();
  }

  /// Сохраняет настройки компании из `employee` ответа `Auth/info`.
  Future<void> saveCompanySettings(Map<String, dynamic> employee) async {
    final credit = employee['creditAcceptance'] as bool? ?? true;
    final payment = employee['paymentAcceptance'] as bool? ?? true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_creditAcceptanceKey, credit);
    await prefs.setBool(_paymentAcceptanceKey, payment);
    creditAcceptanceNotifier.value = credit;
    paymentAcceptanceNotifier.value = payment;
  }

  Future<void> saveInterfaceVisibility({
    bool? showCreditName,
    bool? showCreditCatalog,
    bool? showCreditCategory,
    bool? showNotifications,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (showCreditName != null) {
      await prefs.setBool(_showCreditNameKey, showCreditName);
      showCreditNameNotifier.value = showCreditName;
    }
    if (showCreditCatalog != null) {
      await prefs.setBool(_showCreditCatalogKey, showCreditCatalog);
      showCreditCatalogNotifier.value = showCreditCatalog;
    }
    if (showCreditCategory != null) {
      await prefs.setBool(_showCreditCategoryKey, showCreditCategory);
      showCreditCategoryNotifier.value = showCreditCategory;
    }
    if (showNotifications != null) {
      await prefs.setBool(_showNotificationsKey, showNotifications);
      showNotificationsNotifier.value = showNotifications;
    }
  }

  Future<void> saveNotificationSettings({
    bool? enabled,
    bool? showCreditCreation,
    bool? showWhatsApp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled != null) {
      await prefs.setBool(_notificationsEnabledKey, enabled);
      notificationsEnabledNotifier.value = enabled;
    }
    if (showCreditCreation != null) {
      await prefs.setBool(_showCreditNotificationsKey, showCreditCreation);
      showCreditNotificationsNotifier.value = showCreditCreation;
    }
    if (showWhatsApp != null) {
      await prefs.setBool(_showWhatsAppNotificationsKey, showWhatsApp);
      showWhatsAppNotificationsNotifier.value = showWhatsApp;
    }
  }

  bool get showCreditName => showCreditNameNotifier.value;
  bool get showCreditCatalog => showCreditCatalogNotifier.value;
  bool get showCreditCategory => showCreditCategoryNotifier.value;
  bool get showNotifications => showNotificationsNotifier.value;
  bool get notificationsEnabled => notificationsEnabledNotifier.value;
  bool get showCreditNotifications => showCreditNotificationsNotifier.value;
  bool get showWhatsAppNotifications => showWhatsAppNotificationsNotifier.value;

  bool shouldShowNotificationType(String type) {
    if (!notificationsEnabled) return false;
    if (type == 'credit' && !showCreditNotifications) return false;
    if (type == 'whats_app' && !showWhatsAppNotifications) return false;
    return true;
  }

  bool get paymentAcceptance => paymentAcceptanceNotifier.value;

  /// То же, но прямо из хранилища: при старте приложения уведомитель
  /// может ещё не успеть загрузиться.
  Future<bool> getPaymentAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_paymentAcceptanceKey) ?? true;
  }

  Set<Permission> getPermissionsSync() {
    return permissionsNotifier.value;
  }

  Future<Set<Permission>> getPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_permissionsKey);
    if (list == null) return {};
    return list
        .map((e) => Permission.values.firstWhere((p) => p.name == e))
        .toSet();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_permissionsKey);
    await prefs.remove(_creditAcceptanceKey);
    await prefs.remove(_paymentAcceptanceKey);
    await prefs.remove(_showCreditNameKey);
    await prefs.remove(_showCreditCatalogKey);
    await prefs.remove(_showCreditCategoryKey);
    await prefs.remove(_showNotificationsKey);
    await prefs.remove(_notificationsEnabledKey);
    await prefs.remove(_showCreditNotificationsKey);
    await prefs.remove(_showWhatsAppNotificationsKey);
    roleNotifier.value = null;
    permissionsNotifier.value = {};
    creditAcceptanceNotifier.value = true;
    paymentAcceptanceNotifier.value = true;
    showCreditNameNotifier.value = true;
    showCreditCatalogNotifier.value = true;
    showCreditCategoryNotifier.value = true;
    showNotificationsNotifier.value = true;
    notificationsEnabledNotifier.value = true;
    showCreditNotificationsNotifier.value = true;
    showWhatsAppNotificationsNotifier.value = true;
  }

  bool hasRoleSync(List<EmployeeRole> roles) {
    final role = roleNotifier.value;
    return role != null && roles.contains(role);
  }

  bool forbiddenRoleSync(List<EmployeeRole> roles) {
    final role = roleNotifier.value;
    return role != null && roles.contains(role);
  }

  bool hasPermissionSync(List<Permission> permissions) {
    final role = roleNotifier.value;
    if (_hasAllPrivileges(role)) {
      return true;
    }
    final perms = permissionsNotifier.value;
    return permissions.every((p) => perms.contains(p));
  }

  bool hasAnyPermissionSync(List<Permission> permissions) {
    final role = roleNotifier.value;
    if (_hasAllPrivileges(role)) {
      return true;
    }
    final perms = permissionsNotifier.value;
    return permissions.any((p) => perms.contains(p));
  }

  bool canViewAdminContent() {
    final role = roleNotifier.value;

    return role == EmployeeRole.superAdmin ||
        role == EmployeeRole.director ||
        role == EmployeeRole.admin;
  }

  bool canViewContent() {
    final role = roleNotifier.value;

    return role == EmployeeRole.superAdmin || role == EmployeeRole.director;
  }

  bool hasViewContent(List<EmployeeRole> roles) {
    final role = roleNotifier.value;

    return role != null && roles.contains(role);
  }

  bool hasPermission(Permission permission) {
    final perms = permissionsNotifier.value;
    final hasPermission = perms.contains(permission);

    return hasPermission;
  }

  bool denyPermission(Permission permission) {
    final perms = permissionsNotifier.value;
    return !perms.contains(permission);
  }

  bool _hasAllPrivileges(EmployeeRole? role) {
    return role == EmployeeRole.superAdmin || role == EmployeeRole.director;
  }
}
