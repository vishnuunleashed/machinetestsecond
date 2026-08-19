import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:machinetestsecond/core/di/injection_container.dart';
import 'package:machinetestsecond/core/usecase/usecase.dart';
import 'package:machinetestsecond/features/tasks/domain/entities/task_entity.dart';
import 'package:machinetestsecond/features/tasks/domain/usecases/delete_task.dart';
import 'package:machinetestsecond/features/tasks/domain/usecases/sync_tasks_now.dart';
import 'package:machinetestsecond/features/tasks/domain/usecases/toggle_task_completion.dart';
import 'package:machinetestsecond/features/tasks/domain/usecases/watch_sync_status.dart';
import 'package:machinetestsecond/features/tasks/domain/usecases/watch_tasks.dart';
import 'package:machinetestsecond/features/tasks/presentation/providers/task_list_filter.dart';
import 'package:machinetestsecond/features/tasks/presentation/providers/task_list_notifier.dart';

class MockWatchTasks extends Mock implements WatchTasks {}

class MockWatchSyncStatus extends Mock implements WatchSyncStatus {}

class MockDeleteTask extends Mock implements DeleteTask {}

class MockToggleTaskCompletion extends Mock implements ToggleTaskCompletion {}

class MockSyncTasksNow extends Mock implements SyncTasksNow {}

void main() {
  late MockWatchTasks watchTasks;
  late MockWatchSyncStatus watchSyncStatus;
  late ProviderContainer container;

  final taskA = TaskEntity(
    id: 'a',
    title: 'Buy milk',
    description: '',
    priority: TaskPriority.low,
    dueDate: DateTime(2026, 2, 1),
    isCompleted: false,
    createdAt: DateTime(2025, 12, 1),
  );
  final taskB = TaskEntity(
    id: 'b',
    title: 'Finish report',
    description: '',
    priority: TaskPriority.high,
    dueDate: DateTime(2026, 1, 1),
    isCompleted: true,
    createdAt: DateTime(2025, 12, 1),
  );

  setUp(() async {
    // This architecture's notifiers pull their usecases from `sl` (get_it)
    // directly rather than through Riverpod DI, so the test mirrors that
    // instead of fighting it.
    await sl.reset();

    watchTasks = MockWatchTasks();
    watchSyncStatus = MockWatchSyncStatus();

    when(() => watchTasks(const NoParams()))
        .thenAnswer((_) => Stream.value([taskA, taskB]));
    when(() => watchSyncStatus(const NoParams()))
        .thenAnswer((_) => const Stream.empty());

    sl.registerFactory<WatchTasks>(() => watchTasks);
    sl.registerFactory<WatchSyncStatus>(() => watchSyncStatus);
    sl.registerFactory<DeleteTask>(() => MockDeleteTask());
    sl.registerFactory<ToggleTaskCompletion>(() => MockToggleTaskCompletion());
    sl.registerFactory<SyncTasksNow>(() => MockSyncTasksNow());

    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  Future<void> primeStream() async {
    container.read(taskListNotifierProvider); // triggers build()
    await Future<void>.delayed(Duration.zero); // let the stream emit
  }

  test('search filters tasks by title, case-insensitively', () async {
    await primeStream();

    container
        .read(taskListNotifierProvider.notifier)
        .setSearchQuery('report');

    expect(container.read(taskListNotifierProvider).filteredTasks, [taskB]);
  });

  test('filter shows only completed tasks', () async {
    await primeStream();

    container
        .read(taskListNotifierProvider.notifier)
        .setFilter(TaskFilter.completed);

    expect(container.read(taskListNotifierProvider).filteredTasks, [taskB]);
  });

  test('sort by priority puts the highest priority first', () async {
    await primeStream();

    container
        .read(taskListNotifierProvider.notifier)
        .setSortBy(TaskSortOption.priority);

    expect(
      container.read(taskListNotifierProvider).filteredTasks.first,
      taskB,
    );
  });
}
