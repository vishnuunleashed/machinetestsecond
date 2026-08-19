import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/task_repository.dart';

class ToggleTaskCompletionParams extends Equatable {
  final String id;
  final bool isCompleted;

  const ToggleTaskCompletionParams({
    required this.id,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [id, isCompleted];
}

class ToggleTaskCompletion
    implements UseCase<Unit, ToggleTaskCompletionParams> {
  final TaskRepository repository;

  const ToggleTaskCompletion(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ToggleTaskCompletionParams params) {
    return repository.toggleCompletion(params.id, params.isCompleted);
  }
}
