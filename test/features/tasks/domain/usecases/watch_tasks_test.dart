import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:machinetestsecond/core/usecase/usecase.dart';
import 'package:machinetestsecond/features/tasks/domain/entities/task_entity.dart';
import 'package:machinetestsecond/features/tasks/domain/repositories/task_repository.dart';
import 'package:machinetestsecond/features/tasks/domain/usecases/watch_tasks.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repository;
  late WatchTasks usecase;

  final task = TaskEntity(
    id: '1',
    title: 'Title',
    description: 'Desc',
    priority: TaskPriority.low,
    dueDate: DateTime(2026, 1, 1),
    isCompleted: false,
    createdAt: DateTime(2025, 12, 1),
  );

  setUp(() {
    repository = MockTaskRepository();
    usecase = WatchTasks(repository);
  });

  test('delegates to repository.watchTasks', () async {
    when(() => repository.watchTasks())
        .thenAnswer((_) => Stream.value([task]));

    final result = await usecase(const NoParams()).first;

    expect(result, [task]);
    verify(() => repository.watchTasks()).called(1);
  });
}
