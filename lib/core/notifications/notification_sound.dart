import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Короткий сигнал для уведомления, пришедшего при открытом приложении.
///
/// Когда приложение свёрнуто или закрыто, звук играет система по самому пушу.
/// Этот сигнал нужен только для открытого приложения: там пуш система не
/// озвучивает, а уведомление всё равно приходит — по WebSocket.
class NotificationSound {
  NotificationSound({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  static const _asset = 'sounds/notification.wav';

  Future<void> play() async {
    try {
      // Обрываем предыдущий сигнал: при нескольких уведомлениях подряд
      // наложение звуков звучит как треск.
      await _player.stop();
      await _player.play(AssetSource(_asset));
    } catch (e) {
      // Звук — украшение, из-за него нельзя терять само уведомление.
      debugPrint('⚠️ Не удалось проиграть звук уведомления: $e');
    }
  }

  Future<void> dispose() => _player.dispose();
}
