import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:machinetestsecond/features/tasks/domain/entities/task_entity.dart';
import 'package:machinetestsecond/features/tasks/domain/repositories/task_repository.dart';
import 'package:machinetestsecond/features/tasks/domain/usecases/update_task.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repository;
  late UpdateTask usecase;

  final task = TaskEntity(
    id: '1',
    title: 'Title',
    description: 'Desc',
    priority: TaskPriority.high,
    dueDate: DateTime(2026, 1, 1),
    isCompleted: true,
    createdAt: DateTime(2025, 12, 1),
  );

  setUp(() {
    repository = MockTaskRepository();
    usecase = UpdateTask(repository);
  });

  test('delegates to repository.updateTask', () async {
    when(() => repository.updateTask(task))
        .thenAnswer((_) async => const Right(unit));

    final result = await usecase(task);

    expect(result, const Right(unit));
    verify(() => repository.updateTask(task)).called(1);
  });
}
