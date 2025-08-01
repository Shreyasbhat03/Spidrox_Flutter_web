abstract class ProfileState  {
  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class PulsarUrlLoading extends ProfileState {}

class PulsarUrlLoaded extends ProfileState {
  final String pulsarUrl;
  PulsarUrlLoaded(this.pulsarUrl);

  @override
  List<Object> get props => [pulsarUrl];
}


class UserDataLoading extends ProfileState {}

class UserDataLoaded extends ProfileState {
  final Map<String, dynamic> userData;
  UserDataLoaded(this.userData);

  @override
  List<Object> get props => [userData];
}

class UserDataUpdated extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);

  @override
  List<Object> get props => [message];
}