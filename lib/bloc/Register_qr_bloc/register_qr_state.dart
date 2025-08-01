class RegisterState {

  final int remainingTime;
  final bool isLoading;
  final String? error;
  final String? message;
  final bool isNavigating;

  const RegisterState({

    this.remainingTime = 50,
    this.isLoading = false,
    this.error,
    this.message,
    this.isNavigating = false,
  });

  RegisterState copyWith({
    int? remainingTime,
    bool? isLoading,
    String? error,
    String? message,
    bool? isNavigating,
  }) {
    return RegisterState(
      remainingTime: remainingTime ?? this.remainingTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      message: message ?? this.message,
      isNavigating: isNavigating ?? this.isNavigating,
    );
  }
}
