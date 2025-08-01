class TypingIndicator   {
  final String userId;
  final String receiverId;
  final DateTime startTime;

  const TypingIndicator({
    required this.userId,
    required this.receiverId,
    required this.startTime,
  });

  String get conversationId {
    // Create a consistent conversation ID by sorting the user IDs
    List<String> ids = [userId, receiverId]..sort();
    return 'chatroom_${ids[0]}_${ids[1]}';
  }

  @override
  List<Object?> get props => [userId, receiverId, startTime];
}