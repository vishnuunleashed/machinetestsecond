import 'package:hive/hive.dart';

import '../../../../core/storage/hive_service.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  /// Reactive read of every locally-held task (including sync tombstones —
  /// callers that need the user-facing list filter those out themselves).
  /// Emits an initial value immediately, then again on every local write.
  Stream<List<TaskModel>> watchTasks();

  Future<List<TaskModel>> getAllTasks();

  Future<void> upsertTask(TaskModel task);

  Future<void> deleteTaskLocally(String id);

  Future<List<TaskModel>> getPendingSyncTasks();

  Future<void> markSynced(String id);

  /// Wipes every locally-cached task. Called on sign-out so the next login
  /// doesn't briefly show the previous user's cached tasks.
  Future<void> clearAll();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final HiveService hiveService;

  TaskLocalDataSourceImpl({required this.hiveService});

  Future<Box> get _box => hiveService.tasksBox;

  List<TaskModel> _mapValues(Box box) {
    return box.values
        .map((e) => TaskModel.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Stream<List<TaskModel>> watchTasks() async* {
    final box = await _box;
    yield _mapValues(box);
    yield* box.watch().asyncMap((_) async => _mapValues(box));
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    final box = await _box;
    return _mapValues(box);
  }

  @override
  Future<void> upsertTask(TaskModel task) async {
    final box = await _box;
    await box.put(task.id, task.toMap());
  }

  @override
  Future<void> deleteTaskLocally(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  @override
  Future<List<TaskModel>> getPendingSyncTasks() async {
    final all = await getAllTasks();
    return all.where((t) => t.syncStatus != SyncStatus.synced).toList();
  }

  @override
  Future<void> markSynced(String id) async {
    final box = await _box;
    final raw = box.get(id);
    if (raw == null) return;
    final model = TaskModel.fromMap(Map<dynamic, dynamic>.from(raw as Map));
    await box.put(id, model.copyWithSyncStatus(SyncStatus.synced).toMap());
  }

  @override
  Future<void> clearAll() async {
    final box = await _box;
    await box.clear();
  }
}
