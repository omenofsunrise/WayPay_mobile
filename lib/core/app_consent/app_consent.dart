import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waypay_mobile/blacklist_plus/core/network/token_storage.dart'
    as blacklist_plus;
import 'package:waypay_mobile/core/network/token_storage.dart' as waypay;

/// Единое согласие, которое показывается до выбора сервиса.
class AppConsentController extends ValueNotifier<bool> {
  AppConsentController._() : super(false);

  static final AppConsentController instance = AppConsentController._();

  static const _key = 'app_privacy_policy_accepted';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_key);
    if (accepted == true) {
      value = true;
      await _syncServiceConsent();
      return;
    }

    // Не заставляем действующих пользователей принимать ту же политику
    // повторно после появления общего стартового экрана.
    final legacyAccepted = await Future.wait([
      waypay.TokenStorage().isPrivacyAccepted(),
      blacklist_plus.TokenStorage().isPrivacyAccepted(),
    ]);
    value = legacyAccepted.any((item) => item);
    if (value) {
      await prefs.setBool(_key, true);
      await _syncServiceConsent();
    }
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    await _syncServiceConsent();
    value = true;
  }

  Future<void> _syncServiceConsent() async {
    await Future.wait([
      waypay.TokenStorage().setPrivacyAccepted(true),
      blacklist_plus.TokenStorage().setPrivacyAccepted(true),
    ]);
  }
}
