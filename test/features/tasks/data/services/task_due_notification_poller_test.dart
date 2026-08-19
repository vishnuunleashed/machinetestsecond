import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:machinetestsecond/core/notifications/notification_service.dart';
import 'package:machinetestsecond/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:machinetestsecond/features/tasks/data/models/task_model.dart';
import 'package:machinetestsecond/features/tasks/data/services/task_due_notification_poller.dart';
import 'package:machinetestsecond/features/tasks/domain/entities/task_entity.dart';

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockTaskLocalDataSource local;
  late MockNotificationService notificationService;
  late TaskDueNotificationPoller poller;

  setUpAll(() {
    registerFallbackValue(
      TaskModel(
        id: 'fallback',
        title: '',
        description: '',
        priority: TaskPriority.low,
        dueDate: DateTime(2025, 1, 1),
        isCompleted: false,
        createdAt: DateTime(2025, 1, 1),
        syncStatus: SyncStatus.synced,
        userId: '',
      ),
    );
  });

  setUp(() {
    local = MockTaskLocalDataSource();
    notificationService = MockNotificationService();
    poller = TaskDueNotificationPoller(
      local: local,
      notificationService: notificationService,
    );

    when(() => notificationService.showNow(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});
    when(() => local.upsertTask(any())).thenAnswer((_) async {});
  });

  TaskModel buildTask({
    required bool isCompleted,
    required SyncStatus syncStatus,
    required bool notified,
    required DateTime dueDate,
  }) {
    return TaskModel(
      id: 'task-1',
      title: 'Water the plants',
      description: 'Ficus and monstera',
      priority: TaskPriority.medium,
      dueDate: dueDate,
      isCompleted: isCompleted,
      createdAt: DateTime(2025, 1, 1),
      syncStatus: syncStatus,
      userId: 'user-1',
      notified: notified,
    );
  }

  test('notifies a due, incomplete, un-notified task and marks it notified',
      () async {
    final task = buildTask(
      isCompleted: false,
      syncStatus: SyncStatus.synced,
      notified: false,
      dueDate: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    when(() => local.getAllTasks()).thenAnswer((_) async => [task]);

    await poller.checkNow();

    verify(() => notificationService.showNow(
          id: any(named: 'id'),
          title: 'Task due: Water the plants',
          body: 'Medium priority · Ficus and monstera',
          payload: 'task-1',
        )).called(1);
    final captured = verify(() => local.upsertTask(captureAny())).captured;
    expect((captured.single as TaskModel).notified, isTrue);
  });

  test('does not notify a task not yet due', () async {
    final task = buildTask(
      isCompleted: false,
      syncStatus: SyncStatus.synced,
      notified: false,
      dueDate: DateTime.now().add(const Duration(hours: 2)),
    );
    when(() => local.getAllTasks()).thenAnswer((_) async => [task]);

    await poller.checkNow();

    verifyNever(() => notificationService.showNow(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ));
  });

  test('does not re-notify an already-notified task', () async {
    final task = buildTask(
      isCompleted: false,
      syncStatus: SyncStatus.synced,
      notified: true,
      dueDate: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    when(() => local.getAllTasks()).thenAnswer((_) async => [task]);

    await poller.checkNow();

    verifyNever(() => notificationService.showNow(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ));
  });

  test('does not notify a completed task', () async {
    final task = buildTask(
      isCompleted: true,
      syncStatus: SyncStatus.synced,
      notified: false,
      dueDate: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    when(() => local.getAllTasks()).thenAnswer((_) async => [task]);

    await poller.checkNow();

    verifyNever(() => notificationService.showNow(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ));
  });

  test('does not notify a pendingDelete tombstone', () async {
    final task = buildTask(
      isCompleted: false,
      syncStatus: SyncStatus.pendingDelete,
      notified: false,
      dueDate: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    when(() => local.getAllTasks()).thenAnswer((_) async => [task]);

    await poller.checkNow();

    verifyNever(() => notificationService.showNow(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ));
  });
}
