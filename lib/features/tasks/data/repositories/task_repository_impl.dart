import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

/// Offline-first: every write lands in Hive first and returns immediately —
/// the UI updates instantly via [watchTasks], with no network wait. A
/// best-effort push to Firestore follows in the background; if it fails the
/// task stays flagged pending and [syncNow] retries it later. [syncNow] also
/// runs automatically whenever connectivity comes back online.
///
/// Due-date reminders are handled entirely separately, by
/// `TaskDueNotificationPoller` polling Hive directly — this class doesn't
/// need to know reminders exist.
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource local;
  final TaskRemoteDataSource remote;
  final NetworkInfo networkInfo;
  final FirebaseAuth firebaseAuth;

  final _syncingController = StreamController<bool>.broadcast();
  StreamSubscription<bool>? _connectivitySub;
  bool _isSyncingNow = false;

  TaskRepositoryImpl({
    required this.local,
    required this.remote,
    required this.networkInfo,
    required this.firebaseAuth,
  });

  String get _currentUid => firebaseAuth.currentUser!.uid;

  /// Call once, from DI setup, to auto-sync whenever the device comes back
  /// online. Also fires an initial catch-up sync (fire-and-forget).
  void startAutoSync() {
    _connectivitySub = networkInfo.onConnectivityChanged.listen((online) {
      if (online) syncNow();
    });
    syncNow();
  }

  void dispose() {
    _connectivitySub?.cancel();
    _syncingController.close();
  }

  @override
  Stream<List<TaskEntity>> watchTasks() {
    return local.watchTasks().map(
          (models) => models
              .where((m) => m.syncStatus != SyncStatus.pendingDelete)
              .toList(),
        );
  }

  @override
  Stream<bool> get isSyncing => _syncingController.stream;

  @override
  Future<Either<Failure, Unit>> createTask(TaskEntity task) {
    final model = TaskModel.fromEntity(
      task,
      syncStatus: SyncStatus.pendingCreate,
      userId: _currentUid,
    );
    return _writeLocalThenTrySync(model, () => remote.createTask(model));
  }

  @override
  Future<Either<Failure, Unit>> updateTask(TaskEntity task) {
    final model = TaskModel.fromEntity(
      task,
      syncStatus: SyncStatus.pendingUpdate,
      userId: _currentUid,
    );
    return _writeLocalThenTrySync(model, () => remote.updateTask(model));
  }

  @override
  Future<Either<Failure, Unit>> toggleCompletion(
    String id,
    bool isCompleted,
  ) async {
    final current = await _findLocal(id);
    if (current == null) {
      return const Left(CacheFailure('Task not found'));
    }
    final model = TaskModel.fromEntity(
      current.copyWith(isCompleted: isCompleted),
      syncStatus: SyncStatus.pendingUpdate,
      userId: current.userId,
    );
    return _writeLocalThenTrySync(model, () => remote.updateTask(model));
  }

  @override
  Future<Either<Failure, Unit>> deleteTask(String id) async {
    try {
      final current = await _findLocal(id);
      if (current == null) return const Right(unit);

      if (current.syncStatus == SyncStatus.pendingCreate) {
        // Never reached Firestore — nothing remote to clean up.
        await local.deleteTaskLocally(id);
        return const Right(unit);
      }

      final tombstone = current.copyWithSyncStatus(SyncStatus.pendingDelete);
      await local.upsertTask(tombstone);
      unawaited(_tryPushDelete(tombstone));
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> syncNow() async {
    if (_isSyncingNow) return const Right(unit);

    final online = await networkInfo.isConnected;
    if (!online) return const Left(ServerFailure('No internet connection'));

    _isSyncingNow = true;
    _syncingController.add(true);
    try {
      final pending = await local.getPendingSyncTasks();
      for (final task in pending) {
        await _pushOne(task);
      }

      final remoteTasks = await remote.fetchAllTasks();
      final remoteIds = remoteTasks.map((t) => t.id).toSet();
      final stillPendingIds =
          (await local.getPendingSyncTasks()).map((t) => t.id).toSet();

      for (final remoteTask in remoteTasks) {
        if (!stillPendingIds.contains(remoteTask.id)) {
          await local.upsertTask(remoteTask);
        }
      }

      // Anything locally synced but no longer present remotely was deleted
      // elsewhere — mirror that deletion locally.
      final allLocal = await local.getAllTasks();
      for (final localTask in allLocal) {
        if (localTask.syncStatus == SyncStatus.synced &&
            !remoteIds.contains(localTask.id)) {
          await local.deleteTaskLocally(localTask.id);
        }
      }

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    } finally {
      _isSyncingNow = false;
      _syncingController.add(false);
    }
  }

  Future<TaskModel?> _findLocal(String id) async {
    final all = await local.getAllTasks();
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<Either<Failure, Unit>> _writeLocalThenTrySync(
    TaskModel model,
    Future<void> Function() pushToRemote,
  ) async {
    try {
      await local.upsertTask(model);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
    unawaited(_tryPush(model, pushToRemote));
    return const Right(unit);
  }

  Future<void> _tryPush(
    TaskModel model,
    Future<void> Function() pushToRemote,
  ) async {
    if (!await networkInfo.isConnected) return;
    try {
      await pushToRemote();
      await local.markSynced(model.id);
    } catch (_) {
      // Stays pending; the next syncNow() retries it.
    }
  }

  Future<void> _tryPushDelete(TaskModel tombstone) async {
    if (!await networkInfo.isConnected) return;
    try {
      await remote.deleteTask(tombstone.id);
      await local.deleteTaskLocally(tombstone.id);
    } catch (_) {
      // Stays pendingDelete; the next syncNow() retries it.
    }
  }

  Future<void> _pushOne(TaskModel task) async {
    try {
      switch (task.syncStatus) {
        case SyncStatus.pendingCreate:
          await remote.createTask(task);
          await local.markSynced(task.id);
          break;
        case SyncStatus.pendingUpdate:
          await remote.updateTask(task);
          await local.markSynced(task.id);
          break;
        case SyncStatus.pendingDelete:
          await remote.deleteTask(task.id);
          await local.deleteTaskLocally(task.id);
          break;
        case SyncStatus.synced:
          break;
      }
    } catch (_) {
      // Leave this one pending; the next syncNow() retries it.
    }
  }
}
