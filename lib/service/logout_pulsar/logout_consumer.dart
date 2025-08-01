import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class PulsarLogoutService {
  static final PulsarLogoutService _instance = PulsarLogoutService._internal();
  factory PulsarLogoutService() => _instance;

  WebSocketChannel? _webSocketConsumerChannel;
  String? _currentJwt;
  String? _connectedUrl;

  bool _manuallyDisconnected = false;
  bool _isReconnecting = false;

  final StreamController<String> _messageConsumerController = StreamController<String>.broadcast();

  Stream<String> get messagesStream => _messageConsumerController.stream;

  PulsarLogoutService._internal();

  void connectConsumer(String jwt, String pulsarUrl) {
    // If already connected to same JWT + URL
    if (_currentJwt == jwt && _connectedUrl == pulsarUrl && _webSocketConsumerChannel != null) {
      print("⚡ Already connected to Pulsar with same URL and JWT.");
      return;
    }

    // Disconnect old connection
    if (_webSocketConsumerChannel != null) {
      print("🔌 Disconnecting existing connection...");
      ConsumerLogoutdisconnect();
    }

    _manuallyDisconnected = false;
    _currentJwt = jwt;
    _connectedUrl = pulsarUrl;

    _connectWithRetry();
  }

  void _connectWithRetry([int retryAttempt = 0]) {
    try {
      print("🌐 Connecting to consumer Pulsar WebSocket (attempt $retryAttempt)...");
      _webSocketConsumerChannel = WebSocketChannel.connect(Uri.parse(_connectedUrl!));
      print("✅ Connected to consumer Pulsar WebSocket with url: $_connectedUrl");

      _webSocketConsumerChannel!.stream.listen(
            (message) {
          print("📩 Pulsar Message Received: $message");
          _messageConsumerController.add(message);
        },
        onError: (error) {
          print("🚨 WebSocket error: $error");
          _tryReconnect(retryAttempt);
        },
        onDone: () {
          print("⚠️ WebSocket closed by server.");
          _tryReconnect(retryAttempt);
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("❌ Connection failed: $e");
      _tryReconnect(retryAttempt);
    }
  }

  void _tryReconnect(int previousAttempt) {
    if (_manuallyDisconnected || _isReconnecting) return;

    if (previousAttempt >= 5) {
      print("⛔ Max reconnect attempts reached. Giving up.");
      return;
    }

    _isReconnecting = true;
    final nextAttempt = previousAttempt + 1;
    final delay = Duration(seconds: 1 << previousAttempt);

    print("🔁 Reconnecting in ${delay.inSeconds}s...");

    Future.delayed(delay, () {
      _isReconnecting = false;
      _connectWithRetry(nextAttempt);
    });
  }

  void acknowledgeMessage(String messageId) {
    final ackData = jsonEncode({"messageId": messageId, "ack": true});
    _webSocketConsumerChannel?.sink.add(ackData);
    print("✅ Acknowledged Message ID: $messageId");
  }

  void ConsumerLogoutdisconnect() {
    print("❌ Manual WebSocket disconnect");
    _manuallyDisconnected = true;

    try {
      _webSocketConsumerChannel?.sink.close(status.normalClosure);
    } catch (e) {
      print("⚠️ Error closing WebSocket: $e");
    }

    _webSocketConsumerChannel = null;
    _connectedUrl = null;
    _currentJwt = null;
  }

  void dispose() {
    print("🧹 Disposing PulsarService...");
    ConsumerLogoutdisconnect();
    if (!_messageConsumerController.isClosed) {
      _messageConsumerController.close();
    }
  }
}
