// Timer States
abstract class TimerState {}

class TimerInitial extends TimerState {}

class TimerRunning extends TimerState {
final int remainingTime;
TimerRunning(this.remainingTime);
}

class TimerEnded extends TimerState {}
class TimerNavigation extends TimerState {} // ✅ New State for Navigation
