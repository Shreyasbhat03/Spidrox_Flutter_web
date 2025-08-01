abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String jwt;

  AuthSuccess({required this.jwt});
}

class AuthFailure extends AuthState {
  final String error;

  AuthFailure(this.error);
}
class CollegeNamesLoading extends AuthState {}

class CollegeNamesLoaded extends AuthState {
  final List<String> collegeNames;

  CollegeNamesLoaded(this.collegeNames);
}

class CollegeNamesError extends AuthState {
  final String error;

  CollegeNamesError(this.error);
}