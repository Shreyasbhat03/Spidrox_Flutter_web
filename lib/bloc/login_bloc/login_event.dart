// qr_login_event.dart
abstract class QRLoginEvent {}

/// Event to start the timer and initial QR code fetch.
class StartQRLoginEvent extends QRLoginEvent {
  final int duration;
  StartQRLoginEvent({required this.duration});
}

/// Event fired every second with the updated remaining time.
class TimerTickEvent extends QRLoginEvent {
  final int remainingTime;
  TimerTickEvent(this.remainingTime);
}

/// Event fired when the timer reaches zero.
class TimerCompletedEvent extends QRLoginEvent {}

/// (Optional) Separate event to explicitly fetch the QR code.
class FetchQRCodeEvent extends QRLoginEvent {}

/// Event triggered when QR code scan is successful.
class QRScannedSuccessEvent extends QRLoginEvent {
  final String message;
  QRScannedSuccessEvent({required this.message});
}

/// Event triggered when QR code scan fails.
class QRScannedFailureEvent extends QRLoginEvent {
  final String errorMessage;
  QRScannedFailureEvent({required this.errorMessage});
}

/// Event to trigger navigation to the next page.
class NavigateToNextPageEvent extends QRLoginEvent {}


