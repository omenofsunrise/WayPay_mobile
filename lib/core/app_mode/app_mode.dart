import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Какая из двух программ сейчас открыта в приложении.
enum AppMode { waypay, blacklistPlus }

/// Текущий режим приложения. Запоминается между запусками.
class AppModeController extends ValueNotifier<AppMode> {
  AppModeController._() : super(AppMode.waypay);

  static final AppModeController instance = AppModeController._();

  static const _key = 'app_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    value = AppMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => AppMode.waypay,
    );
  }

  Future<void> switchTo(AppMode mode) async {
    if (value == mode) return;
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
