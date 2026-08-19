import 'package:equatable/equatable.dart';

import '../../../../core/presentation/base_state.dart';

/// State for the login/signup forms (and the sign-out action). Whether the
/// user is actually authenticated is a separate concern — see
/// `authStateProvider` — this only tracks in-flight submit/loading/error.
class AuthFormState extends Equatable implements BaseState {
  @override
  final bool isLoading;
  @override
  final String? errorMessage;

  /// One-shot flag: flips true once sign-up succeeds and the notifier has
  /// signed the (auto-authenticated) new user back out. Login/Signup pages
  /// listen for this to show a confirmation and return to Login.
  final bool isSignupSuccess;

  const AuthFormState({
    required this.isLoading,
    this.errorMessage,
    this.isSignupSuccess = false,
  });

  const AuthFormState.initial()
      : isLoading = false,
        errorMessage = null,
        isSignupSuccess = false;

  AuthFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSignupSuccess,
  }) {
    return AuthFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSignupSuccess: isSignupSuccess ?? this.isSignupSuccess,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, isSignupSuccess];
}
