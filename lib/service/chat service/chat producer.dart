import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ChatProducerService {
  static final ChatProducerService _instance = ChatProducerService._internal();
  factory ChatProducerService() => _instance;

  WebSocketChannel? _webSocketProducerChannel;
  String? _currentJwt;
  bool _isConnected = false;

  final StreamController<String> _messageProducerController = StreamController<String>.broadcast();

  Stream<String> get messagesStream => _messageProducerController.stream;
  bool get isConnected => _isConnected;

  ChatProducerService._internal();

  void connectProducer(String jwt, String pulsarUrl) {
    if (_currentJwt == jwt && _webSocketProducerChannel != null) {
      print("⚡ ChatProducer already connected for this JWT.");
      return;
    }

    _currentJwt = jwt;
    _isConnected = false;

    _webSocketProducerChannel?.sink.close();
    _webSocketProducerChannel = WebSocketChannel.connect(Uri.parse(pulsarUrl));

    print("🌐 Connecting ChatProducer WebSocket with JWT: $jwt");

    _webSocketProducerChannel!.stream.listen(
          (message) {
        print("📩 ChatProducer Message Received: $message");
        _messageProducerController.add(message);
        _isConnected = true; // mark connection established
      },
      onError: (error) {
        print("🚨 ChatProducer error: $error");
        _isConnected = false;
      },
      onDone: () {
        print("⚠️ ChatProducer WebSocket Disconnected.");
        _isConnected = false;
      },
    );
  }

  void sendChatMessage(String message) {
    if (_webSocketProducerChannel != null) {
      try {
        print("📤 Attempting to send message to Pulsar: $message");
        _webSocketProducerChannel!.sink.add(message);
        print("✅ Message sent successfully!");
      } catch (e) {
        print("🚨 Error while sending message to Pulsar: $e");
      }
    } else {
      print("🚨 Cannot send message. WebSocket is not connected.");
    }
  }

  void acknowledgeMessage(String messageId) {
    final ackData = jsonEncode({"messageId": messageId, "ack": true});
    _webSocketProducerChannel?.sink.add(ackData);
    print("✅ ChatProducer acknowledged message: $messageId");
  }

  void disconnect() {
    print("❌ ChatProducer disconnecting...");
    _webSocketProducerChannel?.sink.close(status.normalClosure);
    _webSocketProducerChannel = null;
    _isConnected = false;
  }

  void dispose() {
    print("🧹 Disposing ChatProducer...");
    disconnect();
    _messageProducerController.close();
  }
}
