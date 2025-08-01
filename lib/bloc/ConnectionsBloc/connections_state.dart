
abstract class ConnectionsState  {
  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class ConnectionsInitial extends ConnectionsState {}

/// State when fetching connections from Pulsar
class ConnectionsLoading extends ConnectionsState {}

/// State when connections are successfully fetched and loaded
class ConnectionsLoaded extends ConnectionsState {
  final List<dynamic> connections; // Store fetched connections

  ConnectionsLoaded(this.connections);

  @override
  List<Object?> get props => [connections];
}

/// State when a connection update is successful
class ConnectionUpdated extends ConnectionsState {
  final String message;

  ConnectionUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when there is an error in fetching or updating connections
class ConnectionsError extends ConnectionsState {
  final String error;

  ConnectionsError(this.error);

  @override
  List<Object?> get props => [error];
}
