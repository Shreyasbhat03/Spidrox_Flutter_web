import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../service/chat service/chat producer.dart';
import '../../service/chat service/chat_consumer.dart';
import '../../service/pulsar_consumer.dart';
import '../../service/pulsar_producer.dart';
import '../message_model.dart';
Set<String> _cachedMessageIds = {};

class MessageRepository {
  static final MessageRepository _instance = MessageRepository._internal();
  factory MessageRepository() => _instance;

  late Box<Message> _messagesBox;

  final StreamController<Map<String, List<Message>>> _messagesStreamController =
  StreamController.broadcast();

  final StreamController<Message> _newMessageController =
  StreamController.broadcast();

  Stream<Map<String, List<Message>>> get messagesStream =>
      _messagesStreamController.stream;

  Stream<Message> get newIncomingMessages => _newMessageController.stream;

  final PulsarService pulsarService = PulsarService();
  final PulsarProducerService pulsarProducerService = PulsarProducerService();
  final ChatProducerService chatProducerService = ChatProducerService();
  final ChatConsumerService chatConsumerService = ChatConsumerService();

  String? _currentJwt;
  String? _currentProducerUrl;
  String? _currentConsumerUrl;
  String? _activeTopic;

  StreamSubscription? _consumerSubscription;

  MessageRepository._internal();

  Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MessageAdapter());
    }
    _messagesBox = await Hive.openBox<Message>('messages');
    _cachedMessageIds = _messagesBox.values.map((m) => m.messageId).toSet();
    _notifyListeners();
  }

  /// Connect to Pulsar with given URLs and topic
  Future<void> connectToChat({
    required String jwt,
    required String producerBaseUrl,
    required String consumerBaseUrl,
    required String topicName,
  }) async {
    if (_activeTopic == topicName &&
        _currentJwt == jwt &&
        _currentProducerUrl == producerBaseUrl &&
        _currentConsumerUrl == consumerBaseUrl) {
      print("⚡ Already connected to the same topic:$topicName and URLs.");
      return;
    }

    disconnectFromChat();
    print("🔌 Disconnecting from old connections...");
    // Clean up old connections

    _currentJwt = jwt;
    _currentProducerUrl = producerBaseUrl;
    _currentConsumerUrl = consumerBaseUrl;
    _activeTopic = topicName;

    final fullProducerUrl = "$producerBaseUrl/$topicName";
    final fullConsumerUrl = "$consumerBaseUrl/$topicName/my-subscription";

    print("🔌 Connecting to Producer: $fullProducerUrl");
    print("🔌 Connecting to Consumer: $fullConsumerUrl");

    chatConsumerService.connectConsumer(jwt, fullConsumerUrl);
    chatProducerService.connectProducer(jwt, fullProducerUrl);

    _consumerSubscription = chatConsumerService.messagesStream.listen((raw) async {
      try {
        final data = jsonDecode(raw);
        final payload = utf8.decode(base64Decode(data['payload']));
        final props = data['properties'];

        final messageId = data['messageId'] ?? '';

        // 🧠 Check for duplication
        if (_cachedMessageIds.contains(messageId)) {
          print("⚠️ Duplicate message skipped: $messageId");
          return;
        }

        final message = Message(
          id: const Uuid().v4(),
          messageId: messageId,
          senderId: props['senderId'] ?? 'unknown_sender',
          receiverId: props['receiverId'] ?? 'unknown_receiver',
          content: payload,
          timestamp: DateTime.now(),
        );

        await addMessage(message);
        _newMessageController.add(message);
      } catch (e) {
        print("⚠️ Failed to parse Pulsar message: $e");
      }
    });
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    required String topicName,
  }) async {
    final message = Message(
      id: const Uuid().v4(),
      messageId: const Uuid().v4(),
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
    );

    // await addMessage(message);

    final encodedMessage = base64Encode(utf8.encode(content));

    final pulsarMessage = jsonEncode({
      "payload": encodedMessage,
      "properties": {
        "senderId": senderId,
        "receiverId": receiverId,
        "topic": topicName,
      },
    });

    chatProducerService.sendChatMessage(pulsarMessage);
  }

  Future<void> addMessage(Message message) async {
    if (_cachedMessageIds.contains(message.messageId)) {
      print("⚠️ Message already exists (skip add): ${message.messageId}");
      return;
    }

    await _messagesBox.put(message.id, message);
    _cachedMessageIds.add(message.messageId); // 🧠 Track new message
    _notifyListeners();
  }


  List<Message> getMessages(String userId, String otherUserId) {
    final ids = [userId, otherUserId]..sort();
    final conversationId = '${ids[0]}_${ids[1]}';

    return _messagesBox.values
        .where((m) => m.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void _notifyListeners() {
    final Map<String, List<Message>> conversations = {};

    for (final msg in _messagesBox.values) {
      final convoId = msg.conversationId;
      conversations.putIfAbsent(convoId, () => []).add(msg);
    }

    for (var list in conversations.values) {
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    _messagesStreamController.add(conversations);
  }
  Future<void> fetchUsers({
    required String jwt,
    required String producerUrl,
    required String consumerUrl,
    required String producerTopic,
    required String request,
    required Function(String) onMessage,
  }) async {
    try {
      // Connect to Pulsar producer
      pulsarProducerService.connectProducer(jwt, '$producerUrl/graphsender1');
      await Future.delayed(const Duration(milliseconds: 250));

      // Connect to Pulsar consumer and listen for responses
      pulsarService.connectConsumer(jwt, '$consumerUrl/grapher1/subscriptionType=KeyShared');
      await Future.delayed(const Duration(milliseconds: 250));
      print("🔌 Connecting to consumer URL: $consumerUrl");

      // Setup a subscription for messages
      final subscription = pulsarService.messagesStream.listen(onMessage);

      // Send the request to fetch users
      pulsarProducerService.sendMessage(request, producerTopic);
      print("📤 Sent user fetch request: $request");
      await Future.delayed(Duration(milliseconds: 1500));
      pulsarProducerService.Producerdisconnect();



      // Clean up subscription after some time
       await Future.delayed(const Duration(seconds: 10), () {
        subscription.cancel();


      });
    } catch (e) {
      print("❌ Failed to fetch users: $e");
      throw Exception("Failed to fetch users: $e");
    }
  }

  // Method to acknowledge messages
  void acknowledgeMessage(String messageId) {
    pulsarService.acknowledgeMessage(messageId);
  }
  void disconnectFetcher() {
    print("❌ Disconnecting from fetcher...");
    pulsarService.Consumerdisconnect();
  }

  void disconnectFromChat() {
    print("❌ Disconnecting from chat...");
    // Cancel subscriptions safely
    _consumerSubscription?.cancel();
    _consumerSubscription = null;

    // Disconnect both producer and consumer
    chatConsumerService.disconnect();
    chatProducerService.disconnect();

    // Reset connection state variables
    _currentJwt = null;
    _currentProducerUrl = null;
    _currentConsumerUrl = null;
    _activeTopic = null;
  }

  Future<void> dispose() async {
    print("🗑️ Disposing MessageRepository...");

    // First disconnect from chat (which handles both WebSockets)
    disconnectFromChat();

    // Close stream controllers
    await _messagesStreamController.close();
    await _newMessageController.close();

    // Close storage
    await _messagesBox.close();
  }
}
