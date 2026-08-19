import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/task_repository.dart';

class SyncTasksNow implements UseCase<Unit, NoParams> {
  final TaskRepository repository;

  const SyncTasksNow(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return repository.syncNow();
  }
}
