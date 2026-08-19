import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class UpdateTask implements UseCase<Unit, TaskEntity> {
  final TaskRepository repository;

  const UpdateTask(this.repository);

  @override
  Future<Either<Failure, Unit>> call(TaskEntity params) {
    return repository.updateTask(params);
  }
}
