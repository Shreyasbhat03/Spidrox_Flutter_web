import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ChatConsumerService {
  static final ChatConsumerService _instance = ChatConsumerService._internal();
  factory ChatConsumerService() => _instance;

  WebSocketChannel? _webSocketConsumerChannel;
  String? _currentJwt;
  String? _connectedUrl;

  bool _manuallyDisconnected = false;
  bool _isReconnecting = false;

  final StreamController<String> _messageConsumerController = StreamController<String>.broadcast();

  Stream<String> get messagesStream => _messageConsumerController.stream;

  ChatConsumerService._internal();

  void connectConsumer(String jwt, String pulsarUrl) {
    if (_currentJwt == jwt && _connectedUrl == pulsarUrl && _webSocketConsumerChannel != null) {
      print("⚡ Already connected to ChatConsumer with same JWT and URL.");
      return;
    }

    if (_webSocketConsumerChannel != null) {
      print("🔌 Disconnecting old ChatConsumer...");
      disconnect();
    }

    _manuallyDisconnected = false;
    _currentJwt = jwt;
    _connectedUrl = pulsarUrl;

    _connectWithRetry();
  }

  void _connectWithRetry([int retryAttempt = 0]) {
    try {
      print("🌐 Connecting to ChatConsumer WebSocket (attempt $retryAttempt)...");
      _webSocketConsumerChannel = WebSocketChannel.connect(Uri.parse(_connectedUrl!));
      print("✅ Connected to ChatConsumer WebSocket: $_connectedUrl");

      _webSocketConsumerChannel!.stream.listen(
            (message) {
          print("📩 ChatConsumer Message: $message");
          _messageConsumerController.add(message);
        },
        onError: (error) {
          print("🚨 ChatConsumer error: $error");
          _tryReconnect(retryAttempt);
        },
        onDone: () {
          print("⚠️ ChatConsumer WebSocket closed.");
          _tryReconnect(retryAttempt);
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("❌ ChatConsumer connection failed: $e");
      _tryReconnect(retryAttempt);
    }
  }

  void _tryReconnect(int previousAttempt) {
    if (_manuallyDisconnected || _isReconnecting) return;

    if (previousAttempt >= 5) {
      print("⛔ ChatConsumer: Max reconnect attempts reached.");
      return;
    }

    _isReconnecting = true;
    final nextAttempt = previousAttempt + 1;
    final delay = Duration(seconds: 1 << previousAttempt);

    print("🔁 ChatConsumer reconnecting in ${delay.inSeconds}s...");
    Future.delayed(delay, () {
      _isReconnecting = false;
      _connectWithRetry(nextAttempt);
    });
  }

  void acknowledgeMessage(String messageId) {
    final ackData = jsonEncode({"messageId": messageId, "ack": true});
    _webSocketConsumerChannel?.sink.add(ackData);
    print("✅ ChatConsumer acknowledged message: $messageId");
  }

  void disconnect() {
    print("❌ ChatConsumer manual disconnect");
    _manuallyDisconnected = true;

    try {
      _webSocketConsumerChannel?.sink.close(status.normalClosure);
    } catch (e) {
      print("⚠️ ChatConsumer close error: $e");
    }

    _webSocketConsumerChannel = null;
    _connectedUrl = null;
    _currentJwt = null;
  }

  void dispose() {
    print("🧹 ChatConsumer dispose called");
    disconnect();
    if (!_messageConsumerController.isClosed) {
      _messageConsumerController.close();
    }
  }
}
