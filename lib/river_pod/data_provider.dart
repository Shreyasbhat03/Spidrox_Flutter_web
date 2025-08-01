import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model class for storing JWT and URL
class AuthData {
  final String jwt;
  final String url;

  AuthData({required this.jwt, required this.url,});

  // Copy with method to update individual fields
  AuthData copyWith({String? jwt, String? url,}) {
    return AuthData(
      jwt: jwt ?? this.jwt,
      url: url ?? this.url,
    );
  }
}

// StateNotifier to manage AuthData
class AuthNotifier extends StateNotifier<AuthData> {
  AuthNotifier() : super(AuthData(jwt: "", url: ""));

  // Update only JWT
  void updateJWT(String newJwt) {
    state = state.copyWith(jwt: newJwt);
  }

  // Update only URL
  void updateURL(String newUrl) {
    state = state.copyWith(url: newUrl);
  }

  // Clear both JWT and URL
  void clearData() {
    state = AuthData(jwt: "", url: "");
    print("riverpod data cleared");// Reset to empty values
  }
}

// Global provider to manage JWT and URL
final authProvider = StateNotifierProvider<AuthNotifier, AuthData>((ref) {
  return AuthNotifier();
});



// ✅ login data provider
class LoginData {
  final String Loginjwt;
  final String Loginurl;
  final String ProfileConsumerUrl;
  final String ProfileProducerUrl;
  final String ConnectionConsumerUrl;
  final String ConnectionProducerUrl;
  final String ConsumerConnectUrl;
  final String ProducerConnectUrl;
  final String ProducerConnectTopic;
  final String ProducerRequestUrl;
  final String ConsumerRequestUrl;
  final String ProducerRequestTopic;
  final String ConsumerLogoutUrl;
  final String ProducerLogoutUrl;
  final String producerLogoutTopic;


  LoginData({
    required this.Loginjwt,
    required this.Loginurl,
    required this.ProfileConsumerUrl,
    required this.ProfileProducerUrl,
    required this.ConnectionConsumerUrl,
    required this.ConnectionProducerUrl,
    required this.ConsumerConnectUrl,
    required this.ProducerConnectUrl,
    required this.ProducerConnectTopic,
    required this.ProducerRequestUrl,
    required this.ConsumerRequestUrl,
    required this.ProducerRequestTopic,
    required this.ConsumerLogoutUrl,
    required this.ProducerLogoutUrl,
    required this.producerLogoutTopic,
  });


  LoginData copyWith({
    String? Loginjwt,
    String? Loginurl,
    String? ProfileConsumerUrl,
    String? ProfileProducerUrl,
    String? ConnectionConsumerUrl,
    String? ConnectionProducerUrl,
    String? ConsumerConnectUrl,
    String? ProducerConnectUrl,
    String? ProducerConnectTopic,
    String? ProducerRequestUrl,
    String? ConsumerRequestUrl,
    String? ProducerRequestTopic,
    String? ConsumerLogoutUrl,
    String? ProducerLogoutUrl,
    String? producerLogoutTopic,
  }) {
    return LoginData(
      Loginjwt: Loginjwt ?? this.Loginjwt,
      Loginurl: Loginurl ?? this.Loginurl,
      ProfileConsumerUrl: ProfileConsumerUrl ?? this.ProfileConsumerUrl,
      ProfileProducerUrl: ProfileProducerUrl ?? this.ProfileProducerUrl,
      ConnectionConsumerUrl: ConnectionConsumerUrl ?? this.ConnectionConsumerUrl,
      ConnectionProducerUrl: ConnectionProducerUrl ?? this.ConnectionProducerUrl,
      ConsumerConnectUrl: ConsumerConnectUrl ?? this.ConsumerConnectUrl,
      ProducerConnectUrl: ProducerConnectUrl ?? this.ProducerConnectUrl,
      ProducerConnectTopic: ProducerConnectTopic ?? this.ProducerConnectTopic,
      ProducerRequestUrl: ProducerRequestUrl ?? this.ProducerRequestUrl,
      ConsumerRequestUrl: ConsumerRequestUrl ?? this.ConsumerRequestUrl,
      ProducerRequestTopic: ProducerRequestTopic ?? this.ProducerRequestTopic,
      ConsumerLogoutUrl: ConsumerLogoutUrl ?? this.ConsumerLogoutUrl,
      ProducerLogoutUrl: ProducerLogoutUrl ?? this.ProducerLogoutUrl,
      producerLogoutTopic: producerLogoutTopic ?? this.producerLogoutTopic,
    );
  }

}

// ✅ Updated Notifier
class LoginNotifier extends StateNotifier<LoginData> {
  LoginNotifier()
      : super(LoginData(
    Loginjwt: "",
    Loginurl: "",
    ProfileConsumerUrl: "",
    ProfileProducerUrl: "",
    ConnectionConsumerUrl: "",
    ConnectionProducerUrl: "",
    ConsumerConnectUrl: "",
    ProducerConnectUrl: "",
    ProducerConnectTopic: "",
    ProducerRequestUrl: "",
    ConsumerRequestUrl: "",
    ProducerRequestTopic: "",
    ConsumerLogoutUrl: "",
    ProducerLogoutUrl: "",
    producerLogoutTopic: "",
  ));


  void updateLoginJWT(String newJwt) {
    state = state.copyWith(Loginjwt: newJwt);
  }

  void updateLoginURL(String newUrl) {
    state = state.copyWith(Loginurl: newUrl);
  }

  // ✅ Updated function to update all Pulsar URLs
  void updatePulsarURLs({
    required String profileConsumerUrl,
    required String profileProducerUrl,
    required String connectionConsumerUrl,
    required String connectionProducerUrl,
    required String consumerConnectUrl,
    required String producerConnectUrl,
    required String producerConnectTopic,
    required String producerRequestUrl,
    required String consumerRequestUrl,
    required String producerRequestTopic,
    required String consumerLogoutUrl,
    required String producerLogoutUrl,
    required String producerLogoutTopic,
  }) {
    state = state.copyWith(
      ProfileConsumerUrl: profileConsumerUrl,
      ProfileProducerUrl: profileProducerUrl,
      ConnectionConsumerUrl: connectionConsumerUrl,
      ConnectionProducerUrl: connectionProducerUrl,
      ConsumerConnectUrl: consumerConnectUrl,
      ProducerConnectUrl: producerConnectUrl,
      ProducerConnectTopic: producerConnectTopic,
      ProducerRequestUrl: producerRequestUrl,
      ConsumerRequestUrl: consumerRequestUrl,
      ProducerRequestTopic: producerRequestTopic,
      ConsumerLogoutUrl: consumerLogoutUrl,
      ProducerLogoutUrl: producerLogoutUrl,
      producerLogoutTopic: producerLogoutTopic,
    );
  }

  // ✅ Clear all login data properly
  void clearData() {
    state = LoginData(
      Loginjwt: "",
      Loginurl: "",
      ProfileConsumerUrl: "",
      ProfileProducerUrl: "",
      ConnectionConsumerUrl: "",
      ConnectionProducerUrl: "",
      ConsumerConnectUrl: "",
      ProducerConnectUrl: "",
      ProducerConnectTopic: "",
      ProducerRequestUrl: "",
      ConsumerRequestUrl: "",
      ProducerRequestTopic: "",
      ConsumerLogoutUrl: "",
      ProducerLogoutUrl: "",
      producerLogoutTopic: "",
    );
    print("Riverpod login data cleared");
  }
}

// ✅ Corrected Provider
final loginProvider = StateNotifierProvider<LoginNotifier, LoginData>((ref) {
  return LoginNotifier();
});



///user profile data
// User data state class
class UserDataState {
  final Map<String, dynamic> userData;
  final bool isLoading;
  final bool hasError;

  UserDataState({required this.userData, this.isLoading = false, this.hasError = false});

  UserDataState copyWith({
    Map<String, dynamic>? userData,
    bool? isLoading,
    bool? hasError,
  }) {
    return UserDataState(
      userData: userData ?? this.userData,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}

// StateNotifier for managing user data
class UserDataNotifier extends StateNotifier<UserDataState> {
  UserDataNotifier() : super(UserDataState(userData: {

  }));


  // Fetch user data and store it in Riverpod
  void setUserData(Map<String, dynamic> newUserData) {
    state = state.copyWith(userData: newUserData);
  }

  // Update user data in Riverpod before sending it to Pulsar
  void updateUserData(Map<String, dynamic> updatedData) {
    final updatedState = {...state.userData, ...updatedData};
    state = state.copyWith(userData: updatedState);
  }
}

// Provider for user data
final userDataProvider = StateNotifierProvider<UserDataNotifier, UserDataState>(
      (ref) => UserDataNotifier(),
);