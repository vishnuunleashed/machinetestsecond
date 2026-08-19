import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/base_notifier.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../tasks/data/datasources/task_local_data_source.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../domain/usecases/email_password_params.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import 'auth_form_state.dart';

final authFormNotifierProvider =
    NotifierProvider<AuthFormNotifier, AuthFormState>(AuthFormNotifier.new);

/// Drives the login/signup forms and the sign-out action. Whether the app
/// shows Login vs. Task List is decided separately, by `authStateProvider`
/// reacting to Firebase's own auth stream — this notifier doesn't navigate,
/// it just tracks in-flight submit state so the form UI can react.
class AuthFormNotifier extends BaseNotifier<AuthFormState> {
  late final SignIn _signIn;
  late final SignUp _signUp;
  late final SignOut _signOut;

  @override
  AuthFormState build() {
    _signIn = sl<SignIn>();
    _signUp = sl<SignUp>();
    _signOut = sl<SignOut>();
    return const AuthFormState.initial();
  }

  @override
  AuthFormState loadingState(AuthFormState current) =>
      current.copyWith(isLoading: true, clearError: true);

  @override
  AuthFormState errorState(AuthFormState current, String message) =>
      current.copyWith(isLoading: false, errorMessage: message);

  Future<void> signIn(String email, String password) {
    return guard(
      () => _signIn(EmailPasswordParams(email: email, password: password)),
      (current, _) {
        // TaskRepository is a lazy singleton that only auto-syncs once, at
        // whichever user's session first creates it — switching to a
        // different user afterward needs an explicit fresh pull, or their
        // tasks never get pulled into the (just-cleared) local cache.
        sl<TaskRepository>().syncNow();
        return current.copyWith(isLoading: false, clearError: true);
      },
    );
  }

  /// Firebase auto-signs-in a newly created user, but the product wants a
  /// confirmation step instead of jumping straight into the app — so this
  /// signs back out immediately on success and flips [AuthFormState.isSignupSuccess]
  /// for the Login/Signup pages to react to (confirmation + return to Login).
  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result =
        await _signUp(EmailPasswordParams(email: email, password: password));
    await result.fold(
      (failure) async {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (_) async {
        await _signOut(const NoParams());
        state = state.copyWith(isLoading: false, isSignupSuccess: true);
      },
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _signOut(const NoParams());
    await result.fold(
      (failure) async {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (_) async {
        // Avoid briefly showing the previous user's cached tasks on the
        // next login, before the first post-login sync pull completes.
        await sl<TaskLocalDataSource>().clearAll();
        state = state.copyWith(isLoading: false);
      },
    );
  }
}
