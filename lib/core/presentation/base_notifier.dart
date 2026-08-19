import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failures.dart';
import 'base_state.dart';

/// Base class for every screen's Notifier. Concrete subclasses only need to
/// tell it how to flip their own state's `isLoading`/`errorMessage` flags
/// (via their existing `copyWith`); [guard] then does the fetch-and-branch
/// dance once, instead of every notifier repeating the same
/// try/loading/fold boilerplate.
abstract class BaseNotifier<S extends BaseState> extends Notifier<S> {
  /// Returns [current] with loading turned on (and any previous error
  /// cleared). Typically: `current.copyWith(isLoading: true, clearError: true)`.
  S loadingState(S current);

  /// Returns [current] with loading turned off and [message] set as the
  /// error to display. Typically: `current.copyWith(isLoading: false, errorMessage: message)`.
  S errorState(S current, String message);

  /// Runs [action]; on `Left` builds the error state via [errorState], on
  /// `Right` builds the next state via [onSuccess]. Every screen's "fetch"
  /// method becomes a single call to this.
  Future<void> guard<R>(
    Future<Either<Failure, R>> Function() action,
    S Function(S current, R data) onSuccess,
  ) async {
    state = loadingState(state);

    final result = await action();

    result.fold(
      (failure) => state = errorState(state, failure.message),
      (data) => state = onSuccess(state, data),
    );
  }
}
