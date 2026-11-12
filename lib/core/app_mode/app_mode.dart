import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Какая из двух программ сейчас открыта в приложении.
enum AppMode { waypay, blacklistPlus }

/// Текущий режим приложения. До первого выбора значение отсутствует, поэтому
/// экран выбора появляется раньше любой из двух авторизаций.
class AppModeController extends ValueNotifier<AppMode?> {
  AppModeController._() : super(null);

  static final AppModeController instance = AppModeController._();

  static const _key = 'app_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) {
      value = null;
      return;
    }
    value = AppMode.values.cast<AppMode?>().firstWhere(
      (mode) => mode?.name == saved,
      orElse: () => null,
    );
  }

  Future<void> switchTo(AppMode mode) async {
    if (value == mode) return;
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  Future<void> clearSelection() async {
    value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
