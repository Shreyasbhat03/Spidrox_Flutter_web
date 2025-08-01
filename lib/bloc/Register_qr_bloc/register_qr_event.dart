abstract class RegisterEvent {}

// ✅ Start Timer for QR expiration countdown
class StartTimer extends RegisterEvent {}


// ✅ Timer tick event
class TimerTick extends RegisterEvent {
  final int remainingTime;
  TimerTick(this.remainingTime);
}

// ✅ Timer completed (QR expired)
class TimerCompleted extends RegisterEvent {}

// ✅ Navigate to the next page when verification succeeds
class NavigateToNextPage extends RegisterEvent {}

// ✅ Handle successful verification from Pulsar
class VerificationSuccess extends RegisterEvent {
  final String message;
  VerificationSuccess(this.message);
}

// ✅ Handle verification failure
class VerificationFailure extends RegisterEvent {
  final String errorMessage;
  VerificationFailure(this.errorMessage);
}


