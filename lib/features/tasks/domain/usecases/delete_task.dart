import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/task_repository.dart';

class DeleteTask implements UseCase<Unit, String> {
  final TaskRepository repository;

  const DeleteTask(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String params) {
    return repository.deleteTask(params);
  }
}
