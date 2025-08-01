import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spidrox_reg/gloable_urls/gloable_urls.dart';

import '../../model&repo/repo/hive_repo.dart';
import 'chatbloc_event.dart';
import 'chatbloc_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MessageRepository repository;
  final String currentUserId;
  final String jwt;

  late final StreamSubscription _messageSubscription;
  late final StreamSubscription _newMessageSubscription;

  String? _activeChatUserId;

  // Store fetched users
  List<Map<String, dynamic>> _userList = [];

  ChatBloc({
    required this.repository,
    required this.currentUserId,
    required this.jwt,
  }) : super(ChatInitial()) {

    on<SendMessage>(_handleSendMessage);
    on<LoadMessages>(_handleLoadMessages);
    on<NewMessageReceived>(_handleNewMessage);

    // Add handlers for new events
    on<FetchUsers>(_handleFetchUsers);
    on<UserMessageReceived>(_handleUserMessage);

    repository.initialize().then((_) {
      _messageSubscription = repository.messagesStream.listen((_) {
        if (_activeChatUserId != null) {
          add(LoadMessages(_activeChatUserId!));
        }
      });

      _newMessageSubscription = repository.newIncomingMessages.listen((message) {
        // 🔔 Notify if a message is received from someone else
        if (_activeChatUserId != message.senderId) {
          print("🔔 Incoming message from ${message.senderId}");
          add(NewMessageReceived(message));
        }
      });

      // Fetch users when bloc is initialized
      add(FetchUsers());
    });
  }

  String _generateTopicName(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}${sorted[1]}';
  }

  Future<void> _handleSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    try {
      final topic = _generateTopicName(currentUserId, event.receiverId);
      print("handle message function called");
      // 👇 ensure producer/consumer connected
      await repository.connectToChat(
        jwt: jwt,
        producerBaseUrl: AppConfig().allPulsarUrls["producerBaseUrl"]!,
        consumerBaseUrl: AppConfig().allPulsarUrls["consumerBaseUrl"]!,
        topicName: topic,
      );
      print("✅ Connected to topic: $topic");
      await Future.delayed(const Duration(milliseconds: 300)); // let WebSocket settle
      await repository.sendMessage(
        senderId: currentUserId,
        receiverId: event.receiverId,
        content: event.content,
        topicName: topic,
      );
      print("✅ Message sent to ${event.receiverId}");
      _activeChatUserId = event.receiverId;
      add(LoadMessages(event.receiverId));
    } catch (e) {
      emit(ChatError('Send failed: $e'));
    }
  }

  Future<void> _handleLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final topic = _generateTopicName(currentUserId, event.otherUserId);

      // 👇 ensure connection when loading messages
      await repository.connectToChat(
        jwt: jwt,
        producerBaseUrl: AppConfig().allPulsarUrls["producerBaseUrl"]!,
        consumerBaseUrl:AppConfig().allPulsarUrls["consumerBaseUrl"]!,
        topicName: topic,
      );

      _activeChatUserId = event.otherUserId;

      final messages = repository.getMessages(currentUserId, event.otherUserId);
      emit(ChatLoaded(messages));
    } catch (e) {
      emit(ChatError('Load failed: $e'));
    }
  }

  Future<void> _handleNewMessage(NewMessageReceived event, Emitter<ChatState> emit) async {
    try {
      // Store it and update the UI
      await repository.addMessage(event.message);
      // ⚠️ Only reload if this message is part of current chat
      if (_activeChatUserId == event.message.senderId || _activeChatUserId == event.message.receiverId) {
        add(LoadMessages(_activeChatUserId!));
      }
    } catch (e) {
      emit(ChatError('Receive failed: $e'));
    }
  }

  // New handler for fetching users
  Future<void> _handleFetchUsers(FetchUsers event, Emitter<ChatState> emit) async {
    emit(UsersLoading());
    try {
      // This query should match what you're using in the ConnectionsBloc
      final query = "SELECT string_agg('name: ' || name || ', college: ' || collegename || ', phone: ' || phone || ', profile: ' || profile, E'\n') FROM cypher('my_graph', \$\$ MATCH (me {phone: '$currentUserId'})-[:FRIEND]->(friend) RETURN friend.name AS name, friend.collegename AS collegename, friend.phone AS phone, friend.profile AS profile \$\$) AS (name text, collegename text, phone text, profile text);";

      final requestJson = jsonEncode({
        "query": query,
        "properties": {
          "topic": "graphsender2", // This should match your producer topic
          "queryType": "People",
        }
      });

      // Connect to Pulsar and send the query
      // This method signature should be available in your MessageRepository
      await repository.fetchUsers(
          jwt: jwt,
          producerUrl: AppConfig().allPulsarUrls["producerBaseUrl"]!,
          consumerUrl: AppConfig().allPulsarUrls["consumerBaseUrl"]!,
          producerTopic: "graphsender2",
          request: requestJson,
          onMessage: (message) {
            add(UserMessageReceived(message));
          }
      );

      // If we have cached users, emit them while waiting for fresh data
      if (_userList.isNotEmpty) {
        emit(UsersLoaded(List.from(_userList)));
      }

    } catch (e) {
      print("❌ Error fetching users: $e");
      emit(UsersError("Failed to fetch users: $e"));
    }
  }

  // Handle Pulsar messages with user data
  void _handleUserMessage(UserMessageReceived event, Emitter<ChatState> emit) {
    try {
      final responseData = jsonDecode(event.message);

      if (!responseData.containsKey("payload")) {
        throw Exception("Missing 'payload' field");
      }

      final base64Payload = responseData["payload"];
      final decodedPayloadString = utf8.decode(base64.decode(base64Payload));
      print("📦 Decoded Payload JSON: $decodedPayloadString");

      final decodedPayload = jsonDecode(decodedPayloadString);

      if (!decodedPayload.containsKey("data") || decodedPayload["data"] is! List) {
        throw Exception("Invalid or missing 'data' field");
      }

      final List<dynamic> dataList = decodedPayload["data"];
      final List<Map<String, dynamic>> users = [];

      for (final item in dataList) {
        final result = item["result"];
        if (result is String) {
          final userChunks = result.split(RegExp(r'\bname:')).where((e) => e.trim().isNotEmpty);

          for (final chunk in userChunks) {
            final parts = ('name:' + chunk).split(',').map((e) => e.trim()).toList();
            final Map<String, dynamic> parsed = {};

            for (var part in parts) {
              final kv = part.split(':');
              if (kv.length == 2) {
                final key = kv[0].trim().toLowerCase();
                final value = kv[1].trim();
                parsed[key] = value;
              }
            }

            // Add more user properties as needed
            if (parsed.containsKey("name") && parsed.containsKey("college") && parsed.containsKey("phone")) {
              users.add({
                'name': parsed['name'],
                'lastMessage': 'Tap to start chatting',
                'time': '12:00 PM',
                'unread': 0,
                'phone': parsed['phone'],
                'college': parsed['college'],
                'profile': parsed.containsKey('profile') ? parsed['profile'] : null,
              });
            }
          }
        }
      }

      _userList = users;
      print("✅ Parsed Users: ${users.length} records");
      emit(UsersLoaded(List.from(_userList)));
      repository.disconnectFetcher();

      // Acknowledge the message if needed
      if (responseData.containsKey("messageId")) {
        repository.acknowledgeMessage(responseData["messageId"]);
      }
    } catch (e, stackTrace) {
      print("❌ Error processing user message: $e\n$stackTrace");
      emit(UsersError("Error processing user data: $e"));
    }
  }

  @override
  Future<void> close() async {
    await _messageSubscription.cancel();
    await _newMessageSubscription.cancel();
    repository.disconnectFromChat();
    await repository.dispose();
    return super.close();
  }
}