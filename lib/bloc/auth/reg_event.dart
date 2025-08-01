abstract class AuthEvent {}

class RegisterUser extends AuthEvent {
  final String email;
  final String collagename;
  final String username;

  RegisterUser(this.email, this.username,this.collagename);
}
class FetchCollegeNames extends AuthEvent {}
