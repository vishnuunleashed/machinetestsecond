import 'package:equatable/equatable.dart';

import '../../../../core/presentation/base_state.dart';

class AddEditTaskState extends Equatable implements BaseState {
  @override
  final bool isLoading;
  @override
  final String? errorMessage;

  /// One-shot flag: the page listens for this flipping to `true` to pop
  /// itself, then the notifier resets it.
  final bool isSuccess;

  const AddEditTaskState({
    required this.isLoading,
    this.errorMessage,
    required this.isSuccess,
  });

  const AddEditTaskState.initial()
      : isLoading = false,
        errorMessage = null,
        isSuccess = false;

  AddEditTaskState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
  }) {
    return AddEditTaskState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, isSuccess];
}
