import 'package:hive_flutter/hive_flutter.dart';
part 'message_model.g.dart';
 // only if using build_runner

@HiveType(typeId: 0)
class Message {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String senderId;

  @HiveField(2)
  final String receiverId;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5) // 🆕 Added field
  final String messageId;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.messageId, // 🆕 required
  });

  /// Used to group chats between two users
  String get conversationId {
    final ids = [senderId, receiverId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  bool isFrom(String currentUserId) => senderId == currentUserId;
}
