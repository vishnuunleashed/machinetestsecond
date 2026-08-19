import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:machinetestsecond/core/error/failures.dart';
import 'package:machinetestsecond/core/network/network_info.dart';
import 'package:machinetestsecond/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:machinetestsecond/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:machinetestsecond/features/tasks/data/models/task_model.dart';
import 'package:machinetestsecond/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:machinetestsecond/features/tasks/domain/entities/task_entity.dart';

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late MockTaskLocalDataSource local;
  late MockTaskRemoteDataSource remote;
  late MockNetworkInfo networkInfo;
  late MockFirebaseAuth firebaseAuth;
  late MockUser user;
  late TaskRepositoryImpl repository;

  final task = TaskEntity(
    id: 'task-1',
    title: 'Title',
    description: 'Desc',
    priority: TaskPriority.medium,
    dueDate: DateTime(2026, 1, 1),
    isCompleted: false,
    createdAt: DateTime(2025, 12, 1),
  );

  setUpAll(() {
    registerFallbackValue(TaskModel.fromEntity(task, userId: 'user-1'));
  });

  setUp(() {
    local = MockTaskLocalDataSource();
    remote = MockTaskRemoteDataSource();
    networkInfo = MockNetworkInfo();
    firebaseAuth = MockFirebaseAuth();
    user = MockUser();

    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('user-1');
    when(() => local.upsertTask(any())).thenAnswer((_) async {});

    repository = TaskRepositoryImpl(
      local: local,
      remote: remote,
      networkInfo: networkInfo,
      firebaseAuth: firebaseAuth,
    );
  });

  group('createTask', () {
    test('writes locally and returns Right even while offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.createTask(task);

      expect(result, const Right(unit));
      final captured = verify(() => local.upsertTask(captureAny())).captured;
      final savedModel = captured.single as TaskModel;
      expect(savedModel.syncStatus, SyncStatus.pendingCreate);
      expect(savedModel.userId, 'user-1');
      verifyNever(() => remote.createTask(any()));
    });
  });

  group('syncNow', () {
    test('returns Left and never touches remote when offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.syncNow();

      expect(result, isA<Left<Failure, Unit>>());
      verifyNever(() => remote.fetchAllTasks());
    });

    test('pushes pending tasks to remote when online', () async {
      final pendingModel = TaskModel.fromEntity(
        task,
        syncStatus: SyncStatus.pendingCreate,
        userId: 'user-1',
      );
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => local.getPendingSyncTasks())
          .thenAnswer((_) async => [pendingModel]);
      when(() => remote.createTask(any())).thenAnswer((_) async {});
      when(() => local.markSynced(any())).thenAnswer((_) async {});
      when(() => remote.fetchAllTasks()).thenAnswer((_) async => []);
      when(() => local.getAllTasks()).thenAnswer((_) async => []);

      final result = await repository.syncNow();

      expect(result, const Right(unit));
      verify(() => remote.createTask(pendingModel)).called(1);
      verify(() => local.markSynced('task-1')).called(1);
    });
  });

  group('deleteTask', () {
    test('soft-deletes (tombstones) a previously-synced task', () async {
      final syncedModel = TaskModel.fromEntity(
        task,
        syncStatus: SyncStatus.synced,
        userId: 'user-1',
      );
      when(() => local.getAllTasks()).thenAnswer((_) async => [syncedModel]);
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.deleteTask('task-1');

      expect(result, const Right(unit));
      final captured = verify(() => local.upsertTask(captureAny())).captured;
      final tombstone = captured.single as TaskModel;
      expect(tombstone.syncStatus, SyncStatus.pendingDelete);
      verifyNever(() => local.deleteTaskLocally(any()));
    });

    test('hard-deletes a task that never reached the server', () async {
      final unsyncedModel = TaskModel.fromEntity(
        task,
        syncStatus: SyncStatus.pendingCreate,
        userId: 'user-1',
      );
      when(() => local.getAllTasks())
          .thenAnswer((_) async => [unsyncedModel]);
      when(() => local.deleteTaskLocally('task-1')).thenAnswer((_) async {});

      final result = await repository.deleteTask('task-1');

      expect(result, const Right(unit));
      verify(() => local.deleteTaskLocally('task-1')).called(1);
      verifyNever(() => local.upsertTask(any()));
    });
  });
}
