import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../gloable_urls/gloable_urls.dart';

class PulsarProducerService {
  static final PulsarProducerService _instance = PulsarProducerService._internal();
  factory PulsarProducerService() => _instance;

  WebSocketChannel? _webSocketProducerChannel;
  String? _currentJwt;
  String? get currentJwt => _currentJwt;
  final StreamController<String> _messageProducerController = StreamController.broadcast();

  // Stream to listen for incoming messages
  Stream<String> get messagesStream => _messageProducerController.stream;

  PulsarProducerService._internal();
  /// ✅ **Connect to Pulsar WebSocket**
  void connectProducer(String jwt, String Pulsarurl) {
    if (_currentJwt == jwt && _webSocketProducerChannel != null) {
      print("⚡ Pulsar WebSocket already connected for this JWT.");
      return;
    }

    _currentJwt = jwt;
    _webSocketProducerChannel?.sink.close(); // Close existing connection
    final pulsarUrl = Pulsarurl;

    print("🌐 Connecting to Pulsar producer WebSocket with JWT: $jwt");
    _webSocketProducerChannel = WebSocketChannel.connect(Uri.parse(pulsarUrl));
    print("🌐 Connected to Pulsar producer WebSocket with JWT with url: $pulsarUrl");
    _webSocketProducerChannel!.stream.listen(
          (message) {
        print("📩 Pulsar Message Received: $message");

        _messageProducerController.add(message);
        // ✅ Broadcast message to listeners
      },
      onError: (error) {
        print("🚨 Pulsar WebSocket Error: $error");
      },
      onDone: () {
        print("⚠️ Pulsar WebSocket Disconnected.");
      },
    );
  }
  void sendMessage(String message,String topicName) {
    if (_webSocketProducerChannel != null) {
      String encodedMessage = base64Encode(utf8.encode(message));
      final msg = jsonEncode({"payload": encodedMessage,"properties":{"topic":topicName}}); // ✅ Convert Map to JSON string
      _webSocketProducerChannel!.sink.add(msg); // ✅ Now sending a String
      print("📤 Message sent to Pulsar (Base64 Encoded): $encodedMessage");
      print("sent data $msg");
    } else {
      print("🚨 Cannot send message. WebSocket is not connected.");
    }
  }
  void sendUriMessage(String message,String properties) {
    if (_webSocketProducerChannel != null) {
      String encodedMessage = base64Encode(utf8.encode(message));
      final msg = jsonEncode({"payload": encodedMessage,"properties":properties}); // ✅ Convert Map to JSON string
      _webSocketProducerChannel!.sink.add(msg); // ✅ Now sending a String
      print("📤 Message sent to Pulsar (Base64 Encoded): $encodedMessage");
      print("sent data $msg");
    } else {
      print("🚨 Cannot send message. WebSocket is not connected.");
    }
  }

  void sendConnectionMessage(String message,String topicName,String queryType) {
    if (_webSocketProducerChannel != null) {
      String encodedMessage = base64Encode(utf8.encode(message));
      final msg = jsonEncode({"payload": encodedMessage,"properties":{"topic":topicName,"queryType":queryType}}); // ✅ Convert Map to JSON string
      _webSocketProducerChannel!.sink.add(msg); // ✅ Now sending a String
      print("📤 Message sent to Pulsar (Base64 Encoded): $encodedMessage");
      print("sent data $msg");
    } else {
      print("🚨 Cannot send message. WebSocket is not connected.");
    }
  }

  ///chat purpose send




  void acknowledgeMessage(String messageId) {
    final ackData = jsonEncode({"messageId": messageId, "ack": true});
    _webSocketProducerChannel?.sink.add(ackData);
    print("✅ Acknowledged Message ID: $messageId");
  }

  /// ✅ **Disconnect WebSocket**
  void Producerdisconnect() {
    print("❌ Disconnecting Producer Pulsar WebSocket...");
    _webSocketProducerChannel?.sink.close(status.normalClosure); // ✅ Use 1000 instead of 1001
    _webSocketProducerChannel = null;
  }


  /// ✅ **Dispose Service when App Closes**
  void dispose() {
    _messageProducerController.close();
    Producerdisconnect();
  }
}
