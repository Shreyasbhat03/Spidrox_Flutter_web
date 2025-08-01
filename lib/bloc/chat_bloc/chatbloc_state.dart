
import '../../model&repo/message_model.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  ChatLoaded(this.messages);
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}
class UsersLoading extends ChatState {}

class UsersLoaded extends ChatState {
  final List<Map<String, dynamic>> users;

  UsersLoaded(this.users);
}

class UsersError extends ChatState {
  final String message;

  UsersError(this.message);
}