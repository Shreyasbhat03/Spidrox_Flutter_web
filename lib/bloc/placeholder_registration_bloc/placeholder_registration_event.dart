// Timer Events
abstract class TimerEvent {}

class StartTimerp extends TimerEvent {}

class TimerTicked extends TimerEvent {
  final int remainingTime;
  TimerTicked(this.remainingTime);
}

class TimerCompleted extends TimerEvent {}

class NavigateToNextPageEvent extends TimerEvent {} // ✅ New State for Navigation

class SendUrlToRegisterBloc extends TimerEvent {
  final String url;

  SendUrlToRegisterBloc(this.url);
}
