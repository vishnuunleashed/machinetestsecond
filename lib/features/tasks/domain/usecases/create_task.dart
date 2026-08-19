import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CreateTask implements UseCase<Unit, TaskEntity> {
  final TaskRepository repository;

  const CreateTask(this.repository);

  @override
  Future<Either<Failure, Unit>> call(TaskEntity params) {
    return repository.createTask(params);
  }
}
