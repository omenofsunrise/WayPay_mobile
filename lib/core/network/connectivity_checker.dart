import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:waypay_mobile/core/config/api_config.dart';

/// Определяет, есть ли у устройства реально работающее соединение.
///
/// `connectivity_plus` сообщает лишь тип сетевого интерфейса, а не фактическую
/// доступность сети. При активном VPN (особенно на iOS) плагин может вернуть
/// [ConnectivityResult.none], хотя трафик через туннель проходит нормально.
/// Чтобы не блокировать приложение экраном «нет сети», при отсутствии интерфейса
/// делаем реальную проверку — DNS-запрос до хоста API.
Future<bool> hasWorkingConnection(List<ConnectivityResult> results) async {
  final hasInterface = results.any((r) => r != ConnectivityResult.none);
  if (hasInterface) return true;
  return _canReachApiHost();
}

Future<bool> _canReachApiHost() async {
  try {
    final host = Uri.parse(ApiConfig.apiBaseUrl).host;
    final result = await InternetAddress.lookup(
      host,
    ).timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
