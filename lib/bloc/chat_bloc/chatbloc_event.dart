
import '../../model&repo/message_model.dart';

abstract class ChatEvent {}

class LoadMessages extends ChatEvent {
  final String otherUserId;
  LoadMessages(this.otherUserId);
}

class SendMessage extends ChatEvent {
  final String receiverId;
  final String content;
  SendMessage({required this.receiverId, required this.content});
}

class NewMessageReceived extends ChatEvent {
  final Message message;
  NewMessageReceived(this.message);
}
// New events for fetching users
class FetchUsers extends ChatEvent {}

class UserMessageReceived extends ChatEvent {
  final dynamic message;

  UserMessageReceived(this.message);
}