import 'package:flutter/foundation.dart';

/// Какая из двух программ сейчас открыта в приложении.
enum AppMode { waypay, blacklistPlus }

/// Текущий режим приложения. При каждом новом запуске значение отсутствует,
/// поэтому экран выбора появляется раньше любой из двух авторизаций.
class AppModeController extends ValueNotifier<AppMode?> {
  AppModeController._() : super(null);

  static final AppModeController instance = AppModeController._();

  Future<void> load() async {
    value = null;
  }

  Future<void> switchTo(AppMode mode) async {
    if (value == mode) return;
    value = mode;
  }

  Future<void> clearSelection() async {
    value = null;
  }
}
