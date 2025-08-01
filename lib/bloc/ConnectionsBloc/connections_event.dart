
abstract class ConnectionsEvent {
  @override
  List<Object?> get props => [];
}

/// Event to fetch connections (My Connections, Sent, Received)
class FetchConnections extends ConnectionsEvent {
  final String category; // "my_connections", "sent", "received"

  FetchConnections(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to update the status of a connection (Accept, Reject, Cancel)
class UpdateConnectionStatus extends ConnectionsEvent {
  final String fromConnectionId;
  final String toConnectionId;
  final String status; // "accept", "reject", "cancel"

  UpdateConnectionStatus({
    required this.fromConnectionId,
    required this.toConnectionId,
    required this.status,
  });

  @override
  List<Object?> get props => [
        fromConnectionId,
        toConnectionId,
        status,
      ];
}

/// Event for handling incoming messages from Pulsar
class PulsarMessageReceived extends ConnectionsEvent {
  final String message;

  PulsarMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}
class ChangeSubscriptionTopic extends ConnectionsEvent {
  final String topicName;
  final String tabName;

  ChangeSubscriptionTopic(this.topicName, this.tabName);
}
