import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';

abstract class TaskRepository {
  /// Local-first, reactive task list. Emits immediately from Hive and again
  /// on every local write or sync merge.
  Stream<List<TaskEntity>> watchTasks();

  /// Reflects whether a [syncNow] push/pull is currently in flight.
  Stream<bool> get isSyncing;

  Future<Either<Failure, Unit>> createTask(TaskEntity task);

  Future<Either<Failure, Unit>> updateTask(TaskEntity task);

  Future<Either<Failure, Unit>> deleteTask(String id);

  Future<Either<Failure, Unit>> toggleCompletion(String id, bool isCompleted);

  /// Pushes locally-pending changes to Firestore and pulls down remote
  /// changes. Safe to call anytime; no-ops gracefully when offline.
  Future<Either<Failure, Unit>> syncNow();
}
