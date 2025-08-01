abstract class ProfileEvent {
  @override
  List<Object> get props => [];
}

class FetchPulsarUrl extends ProfileEvent {}
class PulsarMessageReceived extends ProfileEvent {
  final String message;
  PulsarMessageReceived(this.message);
}

class FetchUserData extends ProfileEvent {}

class UpdateUserData extends ProfileEvent {
  final Map<String, dynamic> userData;
  UpdateUserData(this.userData);

  @override
  List<Object> get props => [userData];
}