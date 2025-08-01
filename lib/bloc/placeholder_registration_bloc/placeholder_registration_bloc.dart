import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:spidrox_reg/bloc/placeholder_registration_bloc/placeholder_registration_event.dart';
import 'package:spidrox_reg/bloc/placeholder_registration_bloc/placeholder_registration_state.dart';
import '../../river_pod/data_provider.dart';
import '../../service/pulsar_consumer.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  static const int _initialTime = 300;
  Timer? _timer;
  final PulsarService _pulsarService = PulsarService();
  late StreamSubscription<Map<String, dynamic>> _pulsarSubscription;

  final BehaviorSubject<int> _timerStreamController = BehaviorSubject<int>();

  Stream<int> get timerStream => _timerStreamController.stream;
  final WidgetRef ref;

  TimerBloc(this.ref) : super(TimerInitial()) {
    print("Timer Bloc Started");
    _listenToPulsar(); // ✅ Listen to Pulsar on bloc creation
    on<StartTimerp>(_onStartTimer);
    on<TimerTicked>(_onTimerTicked);
    on<TimerCompleted>(_onTimerCompleted);
    on<NavigateToNextPageEvent>(_onNavigateToNextPage);
  }

  void _onStartTimer(StartTimerp event, Emitter<TimerState> emit) {
    int timeLeft = _initialTime;
    emit(TimerRunning(timeLeft)); // Set initial state

    _timer?.cancel(); // Cancel existing timer before starting a new one

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        timeLeft--;
        add(TimerTicked(
            timeLeft)); // ✅ Dispatch event instead of directly calling emit
      } else {
        _timer?.cancel();
        add(TimerCompleted()); // ✅ Dispatch completion event
      }
    });
  }

  // ✅ Handle Each Tick
  void _onTimerTicked(TimerTicked event, Emitter<TimerState> emit) {
    print("⏰ Timer Ticked: ${event.remainingTime}");
    emit(TimerRunning(event.remainingTime));
  }

  // ✅ Handle Timer Completion
  void _onTimerCompleted(TimerCompleted event, Emitter<TimerState> emit) async {
    print("🚨 Timer Completed");
    if (!emit.isDone) {
      emit(TimerEnded());
      // ✅ Delay closure to prevent emitting after close
      Future.delayed(Duration(seconds: 1), () {
        close();
      });
    }
  }


  /// ✅ **Listen to Pulsar Messages Using RxDart**
  void _listenToPulsar() {
    _pulsarSubscription = _pulsarService.messagesStream
        .map((message) => jsonDecode(message) as Map<String, dynamic>)
        .listen((jsonData) async {
      if (_timerStreamController.isClosed) { // ✅ Check before adding
        print("⚠️ Stream already closed, ignoring message.");
        return;
      }

      print("📩 Received JSON Data: $jsonData");
      final payload = utf8.decode(base64Decode(jsonData["payload"]));
      final parsedPayload = jsonDecode(payload) as Map<String, dynamic>;
      print("decoded payload: $parsedPayload");

      if (parsedPayload.containsKey("url") &&
          parsedPayload["status"] == "true") {
        final String url = parsedPayload["url"];
        print("✅ URL Received: $url");
        ref.read(authProvider.notifier).updateURL(url);
        add(NavigateToNextPageEvent());
      }

      if (jsonData.containsKey("messageId")) {
        _pulsarService.acknowledgeMessage(jsonData["messageId"]);
      }
    }, onError: (error) {
      print("❌ Pulsar Stream Error: $error");
    });
  }


  /// ✅ **Handle Navigation Event**
  void _onNavigateToNextPage(NavigateToNextPageEvent event,
      Emitter<TimerState> emit) {
    print("🚀 Navigating to the next page...");
    _timer?.cancel();
    _timerStreamController.close();
    emit(TimerNavigation());
  }

  @override
  Future<void> close() {
    print("🕒 Timer Bloc Closed");
    _timer?.cancel(); // ✅ Cancel subscription before closing
    _timerStreamController.close(); // ✅ Close stream safely
    return super.close();
  }
}