import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:spidrox_reg/bloc/auth/reg_event.dart';
import 'package:spidrox_reg/bloc/auth/reg_state.dart';
import 'package:spidrox_reg/gloable_urls/gloable_urls.dart';
import '../../river_pod/data_provider.dart';
import '../../service/pulsar_consumer.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // RxDart BehaviorSubjects for email and username
  final BehaviorSubject<String> emailSubject = BehaviorSubject<String>();
  final BehaviorSubject<String> usernameSubject = BehaviorSubject<String>();
  final BehaviorSubject<List<String>> collegeNamesSubject = BehaviorSubject<List<String>>();


  final BehaviorSubject<AuthState> _authSubject = BehaviorSubject<AuthState>();
  Stream<AuthState> get authStream => _authSubject.stream;
  final PulsarService _pulsarService = PulsarService();
  final WidgetRef ref;

  AuthBloc(this.ref) : super(AuthInitial()) {

    on<RegisterUser>((event, emit) async {
      /// Check for empty fields
      if (event.email.isEmpty || event.username.isEmpty || event.collagename.isEmpty) {
        final errorMsg = "Email, Username, and College Name must not be empty.";
        emit(AuthFailure(errorMsg));
        _authSubject.add(AuthFailure(errorMsg));
        return;
      }

      // Update subjects
      emailSubject.add(event.email);
      usernameSubject.add(event.username);

      // Start registration process
      emit(AuthLoading());
      _authSubject.add(AuthLoading());

      try {
        // Prepare API request
        final url = Uri.parse("${AppConfig().getRestApiUrl("register_post")}");
        final body = jsonEncode({
        "method": "POST",
        "resource": "/users",
        "body":{
        "name": event.username,
        "email": event.email,
        "collegename": event.collagename,
        },
        }
        ).toString();

        final response = await http.post(
          url,
          headers: {"Content-Type": "text/plain"},  // ✅ Changed to JSON instead of text/plain
          body: body,
        );

        // Debugging prints
        print("📤 Sending Data: $body");
        print("📥 Response Code: ${response.statusCode}");
        print("📥 Response Body: ${response.body}");

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData.containsKey("JwtToken")) {
            final String jwt = responseData["JwtToken"];
            _pulsarService.connectConsumer(jwt,"${AppConfig().getPulsarUrl("register_topic")}"); // ✅ Connect Pulsar WebSocket with JWT
            emit(AuthSuccess( jwt:jwt)); // ✅ Store JWT in state
            _authSubject.add(AuthSuccess( jwt:jwt));
            ref.read(authProvider.notifier).updateJWT(jwt);
          } else {
            final errorMsg = "⚠ Registration Success but JWT Missing";
            emit(AuthFailure(errorMsg));
            _authSubject.add(AuthFailure(errorMsg));
          }
        } else {
          final errorMsg = "⚠ Registration Failed: ${response.body}";
          emit(AuthFailure(errorMsg));
          _authSubject.add(AuthFailure(errorMsg));
        }
      } catch (e) {
        final errorMsg = "❌ Error: ${e.toString()}";
        emit(AuthFailure(errorMsg));
        _authSubject.add(AuthFailure(errorMsg));
        print(errorMsg);
      }
    });
/// collage name getter
    on<FetchCollegeNames>((event, emit) async {
      emit(CollegeNamesLoading());

      try {
        final url = Uri.parse("${AppConfig().getRestApiUrl("get_colleges")}");
        final response = await http.get(url);

        // Debugging prints
        print("📥 College List Response Code: ${response.statusCode}");
        print("📥 College List Response Body: ${response.body}");

        if (response.statusCode == 200) {
          // ✅ Correctly decode the JSON response as a Map
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          // ✅ Extract the 'colleges' list safely
          final List<String> collegeNames = List<String>.from(jsonResponse["colleges"]);

          // ✅ Update the Bloc state
          collegeNamesSubject.add(collegeNames);
          emit(CollegeNamesLoaded(collegeNames));
        } else {
          final errorMsg = "⚠ Failed to load college names: ${response.body}";
          emit(CollegeNamesError(errorMsg));
          print(errorMsg);
        }
      } catch (e) {
        final errorMsg = "❌ Error loading college names: ${e.toString()}";
        emit(CollegeNamesError(errorMsg));
        print(errorMsg);
      }
    });

  }

  @override
  Future<void> close() {
    print("registration bloc Closed");
    emailSubject.close();
    usernameSubject.close();
    _authSubject.close();
    collegeNamesSubject.close();
    return super.close();
  }
}
