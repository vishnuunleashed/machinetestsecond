import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:machinetestsecond/features/tasks/domain/repositories/task_repository.dart';
import 'package:machinetestsecond/features/tasks/domain/usecases/toggle_task_completion.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repository;
  late ToggleTaskCompletion usecase;

  setUp(() {
    repository = MockTaskRepository();
    usecase = ToggleTaskCompletion(repository);
  });

  test('delegates to repository.toggleCompletion', () async {
    when(() => repository.toggleCompletion('task-1', true))
        .thenAnswer((_) async => const Right(unit));

    final result = await usecase(
      const ToggleTaskCompletionParams(id: 'task-1', isCompleted: true),
    );

    expect(result, const Right(unit));
    verify(() => repository.toggleCompletion('task-1', true)).called(1);
  });
}
