// qr_login_bloc.dart
import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:spidrox_reg/river_pod/data_provider.dart';
import 'package:spidrox_reg/service/pulsar_consumer.dart';
import '../../gloable_urls/gloable_urls.dart';
import '../../river_pod/future_provider.dart';
import 'login_event.dart';
import 'login_state.dart';

class QRLoginBloc extends Bloc<QRLoginEvent, QRLoginState> {
  StreamSubscription<String>? _pulsarSubscription;
  PulsarService _pulsarService=PulsarService();
  String? _currentJwt;
  Timer? _timer;
  final int refreshInterval = 400;
  final WidgetRef ref;


  QRLoginBloc(this.ref) : super(const QRLoginState(remainingTime: 100)) {
    // When the bloc is created, start the timer with the initial duration.
    on<StartQRLoginEvent>(_onStart);
    on<TimerTickEvent>(_onTick);
    on<TimerCompletedEvent>(_onTimerCompleted);
    on<FetchQRCodeEvent>(_onFetchQRCode);
    on<QRScannedSuccessEvent>(_onQRScannedSuccess);
    on<QRScannedFailureEvent>(_onQRScannedFailure);
    on<NavigateToNextPageEvent>(_onNavigateToNextPage);

    // Start the process.
    add(StartQRLoginEvent(duration: refreshInterval));
  }

  void _onStart(StartQRLoginEvent event, Emitter<QRLoginState> emit) async {
    // Start the timer.
    _startTimer(event.duration);
    // Immediately fetch the QR code.
    add(FetchQRCodeEvent());
    emit(state.copyWith(remainingTime: event.duration));
  }

  void _onTick(TimerTickEvent event, Emitter<QRLoginState> emit) {
    emit(state.copyWith(remainingTime: event.remainingTime));
    print(event.remainingTime);
  }

  Future<void> _onTimerCompleted(TimerCompletedEvent event, Emitter<QRLoginState> emit) async {
    emit(state.copyWith(remainingTime: refreshInterval, status: QRLoginStatus.loading));
    add(FetchQRCodeEvent());
    _startTimer(refreshInterval);
  }

  Future<void> _onFetchQRCode(FetchQRCodeEvent event, Emitter<QRLoginState> emit) async {
    try {
      final qrData = await _fetchQRCode();
      print(qrData);
      emit(state.copyWith(
        jwt: qrData["jwt"],
        url: qrData["url"],
        status: QRLoginStatus.scanning,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(status: QRLoginStatus.failure, error: e.toString()));
    }
  }
  void _startTimer(int duration) {
    _timer?.cancel();
    int seconds = duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds > 0) {
        seconds--;
        add(TimerTickEvent(seconds));
      } else {
        add(TimerCompletedEvent());
        disconnectWebSocket();
        timer.cancel();
      }
    });
  }

  Future<Map<String, String>> _fetchQRCode() async {
    final String url =
        '${AppConfig().getRestApiUrl("login_qr")}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data.containsKey("jwt_token") && data.containsKey("url")) {
        _currentJwt= data["jwt_token"];

        _connectWebSocket(_currentJwt!);
        return {
          "jwt": data["jwt_token"],
          "url": data["url"],
        };
      }
      throw Exception("Invalid response format");
    }
    throw Exception("Failed to fetch QR code, status: ${response.statusCode}");
  }
  void _connectWebSocket(String jwt) {
    print("🔌 Connecting to Pulsar via PulsarService...");
    _pulsarService.connectConsumer(jwt, "${AppConfig().getPulsarUrl("login_topic")}");
    _pulsarSubscription = _pulsarService.messagesStream.listen((message) async {
      print("📩 Received WebSocket Message: $message");
        print("current jwt: $_currentJwt");
        try {
          final jsonData = jsonDecode(message) as Map<String, dynamic>;

          // Check if the required keys exist
          if (!jsonData.containsKey("payload") || !jsonData.containsKey("properties")) {
            print("⚠️ Missing keys in message: $jsonData");
            emit(state.copyWith(status: QRLoginStatus.failure, error: "Invalid message format"));
            return;
          }

          // Decode Base64 payload
          final decodedPayload = utf8.decode(base64Decode(jsonData["payload"]));
          print("🔍 Decoded Payload: $decodedPayload");

          // Parse JSON from decoded payload
          final payloadData = jsonDecode(decodedPayload);

          // Extract key
          final key = jsonData["properties"]["key"];
          print("🔑 Received Key: $key");
          print("🔑 Expected JWT Key: $_currentJwt");

            if(_currentJwt?.trim()==key?.trim()) {
              if (payloadData["status"]?.trim() == "true" &&
                  payloadData["url"] != null) {
                print("✅ Login Verified! Navigating...");
                add(QRScannedSuccessEvent(message: "Login Successful"));
                ref.read(loginProvider.notifier).updateLoginJWT(_currentJwt!);
                ref.read(loginProvider.notifier).updateLoginURL(
                    payloadData["url"]!);
                print("✅ URL Received: ${ref
                    .watch(loginProvider)
                    .Loginurl},and jwt : ${ref
                    .watch(loginProvider)
                    .Loginjwt}");
                add(NavigateToNextPageEvent());
                disconnectWebSocket();
                await ref.read(pulsarUrlProvider.future);
              } else {
                print("❌ Login Failed! Status: ${payloadData["status"]}");
                add(QRScannedFailureEvent(errorMessage: "Login Failed"));
              }
            }else{
              print("Jwt missmatched");
            }
            _acknowledgeMessage(jsonData);


        } catch (e, stackTrace) {
          print("❌ Error Processing WebSocket Message: $e");
          print(stackTrace);
          emit(state.copyWith(status: QRLoginStatus.failure, error: e.toString()));
        }
      },
      onError: (error) {
        print("🚨 WebSocket Error Occurred: $error");
        emit(state.copyWith(status: QRLoginStatus.failure, error: error.toString()));
      },
      onDone: () {
        print("⚠️ WebSocket Connection Closed");
        emit(state.copyWith(status: QRLoginStatus.failure, error: "WebSocket Connection Closed"));
      },
    );

  }

  void _acknowledgeMessage(Map<String, dynamic> jsonData) {
    _pulsarService.acknowledgeMessage(jsonData["messageId"]);
  }


  void _onQRScannedSuccess(QRScannedSuccessEvent event, Emitter<QRLoginState> emit) {
    print("pulsar Successful");
    emit(state.copyWith(status: QRLoginStatus.success, message: event.message));
  }

  void _onQRScannedFailure(QRScannedFailureEvent event, Emitter<QRLoginState> emit) {
    print("pulsar Failed ${event.errorMessage}");
    emit(state.copyWith(status: QRLoginStatus.failure, error: event.errorMessage));
  }

  void _onNavigateToNextPage(NavigateToNextPageEvent event, Emitter<QRLoginState> emit) {
    print("nextpage");
    emit(state.copyWith(status: QRLoginStatus.navigating));
  }

  void disconnectWebSocket() {
    print("❌ Disconnecting from Pulsar via PulsarService...");
    _pulsarService.Consumerdisconnect();
  }



  @override
  Future<void> close() {
    print("closing login bloc in bloc");
    _timer?.cancel();
    _pulsarSubscription?.cancel();
    return super.close();
  }
}
