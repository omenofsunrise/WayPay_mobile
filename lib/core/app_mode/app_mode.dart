import 'package:flutter/foundation.dart';
import 'package:waypay_mobile/blacklist_plus/core/network/token_storage.dart'
    as blacklist_plus;
import 'package:waypay_mobile/core/network/token_storage.dart' as waypay;

/// Какая из двух программ сейчас открыта в приложении.
enum AppMode { waypay, blacklistPlus }

/// Текущий режим приложения. При каждом новом запуске значение отсутствует,
/// поэтому экран выбора появляется раньше любой из двух авторизаций.
class AppModeController extends ValueNotifier<AppMode?> {
  AppModeController._() : super(null);

  static final AppModeController instance = AppModeController._();

  AppMode? _pendingMode;

  Future<void> load() async {
    value = null;
  }

  Future<void> switchTo(AppMode mode) async {
    if (value == mode) return;
    _pendingMode = mode;

    try {
      await _prepareSession(mode);
    } catch (_) {
      // Ошибка предварительной проверки не должна блокировать открытие:
      // роутер повторит штатную проверку и покажет нужный экран авторизации.
    }
    if (_pendingMode != mode) return;

    value = mode;
    _pendingMode = null;
  }

  Future<void> clearSelection() async {
    _pendingMode = null;
    value = null;
  }

  Future<void> _prepareSession(AppMode mode) async {
    if (mode == AppMode.blacklistPlus) {
      final storage = blacklist_plus.TokenStorage();
      if (await storage.isAuthenticated()) {
        await storage.getAccessToken();
      }
      return;
    }

    final storage = waypay.TokenStorage();
    if (await storage.isAuthenticated()) {
      await storage.getAccessToken();
    }
  }
}
