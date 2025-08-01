import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spidrox_reg/bloc/Register_qr_bloc/register_qr_event.dart';
import 'package:spidrox_reg/bloc/Register_qr_bloc/register_qr_state.dart';
import 'package:spidrox_reg/river_pod/data_provider.dart';
import '../../service/pulsar_consumer.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  static const int _initialTime = 100;
  Timer? _timer;
  final PulsarService _pulsarService = PulsarService();
  StreamSubscription? _pulsarSubscription;
  final WidgetRef ref;

  RegisterBloc(this.ref) : super(RegisterState()) {
    print("✅ RegisterBloc in placegoder CREATED");

    _listenToPulsar(); // ✅ Listen to Pulsar messages
    on<StartTimer>(_onStartTimer);
    on<NavigateToNextPage>(_onNavigateToNextPage);
    on<TimerTick>(_onTimerTick);
    on<TimerCompleted>(_onTimerCompleted);
  }


  /// ✅ **Start Timer for QR Expiry**
  void _onStartTimer(StartTimer event, Emitter<RegisterState> emit) {
    int timeLeft = _initialTime;
    emit(state.copyWith(remainingTime: timeLeft, isLoading: false));

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        timeLeft--;
        add(TimerTick(timeLeft));
      } else {
        timer.cancel();
        add(TimerCompleted());
      }
    });
  }

  /// ✅ **Handle Timer Tick**
  void _onTimerTick(TimerTick event, Emitter<RegisterState> emit) {
    emit(state.copyWith(remainingTime: event.remainingTime));
  }

  /// ✅ **Handle Timer Completion**
  void _onTimerCompleted(TimerCompleted event, Emitter<RegisterState> emit) {
    emit(state.copyWith(remainingTime: 0));
  }

  /// ✅ **Listen to Pulsar Messages**
  void _listenToPulsar() {
    _pulsarSubscription = _pulsarService.messagesStream.listen((message) {
      try {
        final Map<String, dynamic> jsonData = jsonDecode(message);
        final String payloadEncoded = jsonData["payload"];
        final Map<String, dynamic> payloadDecoded = jsonDecode(utf8.decode(base64Decode(payloadEncoded)));

        print("📩 Pulsar Message Received: $payloadDecoded");

        if (payloadDecoded["status"] == "true" && payloadDecoded.containsKey("message")) {
          final String message = payloadDecoded["message"];
          print("✅ Received URL from Pulsar: $message");

          // Fire the event to EventBus
       add(NavigateToNextPage());
        }
      } catch (error) {
        print("❌ Error Parsing Pulsar Message: $error");
      }
    });
  }

  /// ✅ **Navigate to Next Page**
  void _onNavigateToNextPage(NavigateToNextPage event, Emitter<RegisterState> emit) {
    emit(state.copyWith(isNavigating: true));
    ref.read(authProvider.notifier).clearData();
  }

  @override
  Future<void> close() {
    print("❌ RegisterBloc Closed");
    _timer?.cancel();
    _pulsarSubscription?.cancel();
    return super.close();
  }
}
