import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:waypay_mobile/core/network/notification_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Поддельный канал: отдаёт то, что положили в [incoming],
/// и запоминает всё отправленное в [sent].
class _FakeChannel extends StreamChannelMixin implements WebSocketChannel {
  _FakeChannel() : _incoming = StreamController<dynamic>();

  final StreamController<dynamic> _incoming;
  final List<String> sent = [];
  bool closed = false;

  void push(Object message) => _incoming.add(message);
  void breakConnection() => _incoming.close();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _FakeSink(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this._channel);
  final _FakeChannel _channel;

  @override
  void add(dynamic data) => _channel.sent.add(data.toString());

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    _channel.closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('NotificationSocket', () {
    test('сразу после подключения отправляет рукопожатие с EmployeeId', () {
      final channel = _FakeChannel();
      final socket = NotificationSocket(
        url: 'ws://test/ws',
        connector: (_) => channel,
      );

      socket.connect(28);

      expect(channel.sent, hasLength(1));
      expect(jsonDecode(channel.sent.single), {'EmployeeId': 28});

      socket.dispose();
    });

    test('входящее уведомление попадает в поток', () async {
      final channel = _FakeChannel();
      final socket = NotificationSocket(
        url: 'ws://test/ws',
        connector: (_) => channel,
      );
      socket.connect(28);

      final received = socket.messages.first;

      channel.push(
        jsonEncode({
          'Type': 'notification',
          'Title': 'Напоминание',
          'Body': 'Позвонить клиенту',
          'Route': 'credits/777',
        }),
      );

      final message = await received;
      expect(message.title, 'Напоминание');
      expect(message.body, 'Позвонить клиенту');
      expect(message.creditId, 777);

      socket.dispose();
    });

    test('мусор в сокете не роняет поток', () async {
      final channel = _FakeChannel();
      final socket = NotificationSocket(
        url: 'ws://test/ws',
        connector: (_) => channel,
      );
      socket.connect(28);

      final received = socket.messages.first;

      channel.push('это не json');
      channel.push(jsonEncode({'Title': 'Дошло', 'Body': 'Б'}));

      expect((await received).title, 'Дошло');

      socket.dispose();
    });

    test('после обрыва переподключается и снова здоровается', () async {
      final channels = <_FakeChannel>[];
      final socket = NotificationSocket(
        url: 'ws://test/ws',
        connector: (_) {
          final channel = _FakeChannel();
          channels.add(channel);
          return channel;
        },
        reconnectDelay: const Duration(milliseconds: 10),
      );

      socket.connect(28);
      expect(channels, hasLength(1));

      channels.first.breakConnection();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(channels.length, greaterThanOrEqualTo(2));
      expect(jsonDecode(channels.last.sent.single), {'EmployeeId': 28});

      socket.dispose();
    });

    test('disconnect забывает сотрудника и не переподключается', () async {
      final channels = <_FakeChannel>[];
      final socket = NotificationSocket(
        url: 'ws://test/ws',
        connector: (_) {
          final channel = _FakeChannel();
          channels.add(channel);
          return channel;
        },
        reconnectDelay: const Duration(milliseconds: 10),
      );

      socket.connect(28);
      socket.disconnect();
      channels.first.breakConnection();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(channels, hasLength(1));
      expect(socket.isConnected, isFalse);

      socket.dispose();
    });
  });
}
