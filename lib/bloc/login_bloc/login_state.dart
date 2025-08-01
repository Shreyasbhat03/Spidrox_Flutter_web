enum QRLoginStatus {
  initial,
  loading,
  success,
  failure,
  scanning,
  navigating,
}

class QRLoginState {
  final QRLoginStatus status;
  final String? jwt;
  final String? url;
  final int remainingTime;
  final String? message;
  final String? error;

  const QRLoginState({
    this.status = QRLoginStatus.initial,
    this.jwt,
    this.url,
    this.remainingTime = 60,
    this.message,
    this.error,
  });

  QRLoginState copyWith({
    QRLoginStatus? status,
    String? jwt,
    String? url,
    int? remainingTime,
    String? message,
    String? error,
  }) {
    return QRLoginState(
      status: status ?? this.status,
      jwt: jwt ?? this.jwt,
      url: url ?? this.url,
      remainingTime: remainingTime ?? this.remainingTime,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is QRLoginState &&
        other.status == status &&
        other.jwt == jwt &&
        other.url == url &&
        other.remainingTime == remainingTime &&
        other.message == message &&
        other.error == error;
  }

  @override
  int get hashCode {
    return status.hashCode ^
    jwt.hashCode ^
    url.hashCode ^
    remainingTime.hashCode ^
    message.hashCode ^
    error.hashCode;
  }
}
