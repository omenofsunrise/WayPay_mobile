import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';

class ChatHubService {
  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  HubConnection? _hub;

  final _receiveMessageCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _userTypingCtrl = StreamController<_TypingEvent>.broadcast();

  Stream<Map<String, dynamic>> get onReceiveMessage =>
      _receiveMessageCtrl.stream;
  Stream<_TypingEvent> get onUserTyping => _userTypingCtrl.stream;

  ChatHubService({required this.baseUrl, required this.tokenProvider});

  Future<void> connect() async {
    if (_hub?.state == HubConnectionState.Connected) return;

    _hub = HubConnectionBuilder()
        .withUrl(
          '$baseUrl/chatHub',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => (await tokenProvider()) ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hub!.on('ReceiveMessage', (List<Object?>? args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map) {
        _receiveMessageCtrl.add(Map<String, dynamic>.from(data));
      }
    });

    _hub!.on('UserTyping', (List<Object?>? args) {
      if (args == null || args.length < 3) return;
      try {
        final chatId = (args[0] as num).toInt();
        final userId = (args[1] as num).toInt();
        final userName = args[2]?.toString();
        _userTypingCtrl.add(
          _TypingEvent(chatId: chatId, userId: userId, userName: userName),
        );
      } catch (_) {}
    });

    await _hub!.start();
  }

  bool get isConnected => _hub?.state == HubConnectionState.Connected;

  Future<void> disconnect() async {
    if (_hub != null) {
      await _hub!.stop();
      _hub = null;
    }
  }

  Future<void> joinChat(int chatId) async {
    await _ensureConnected();
    await _hub!.invoke('JoinChat', args: <Object>[chatId]);
  }

  Future<void> leaveChat(int chatId) async {
    await _ensureConnected();
    await _hub!.invoke('LeaveChat', args: <Object>[chatId]);
  }

  Future<void> notifyTyping({
    required int chatId,
    required int userId,
    required String userName,
  }) async {
    await _ensureConnected();
    await _hub!.invoke(
      'NotifyTyping',
      args: <Object>[chatId, userId, userName],
    );
  }

  Future<void> sendMessageToChat(
    int chatId,
    Map<String, dynamic> messageJson,
  ) async {
    await _ensureConnected();
    await _hub!.invoke(
      'SendMessageToChat',
      args: <Object>[chatId, messageJson],
    );
  }

  Future<void> _ensureConnected() async {
    if (!isConnected) {
      await connect();
    }
  }

  void dispose() {
    _receiveMessageCtrl.close();
    _userTypingCtrl.close();
    disconnect();
  }
}

class _TypingEvent {
  final int chatId;
  final int userId;
  final String? userName;
  _TypingEvent({required this.chatId, required this.userId, this.userName});
}
