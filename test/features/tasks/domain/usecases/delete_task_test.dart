import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:machinetestsecond/features/tasks/domain/repositories/task_repository.dart';
import 'package:machinetestsecond/features/tasks/domain/usecases/delete_task.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repository;
  late DeleteTask usecase;

  setUp(() {
    repository = MockTaskRepository();
    usecase = DeleteTask(repository);
  });

  test('delegates to repository.deleteTask', () async {
    when(() => repository.deleteTask('task-1'))
        .thenAnswer((_) async => const Right(unit));

    final result = await usecase('task-1');

    expect(result, const Right(unit));
    verify(() => repository.deleteTask('task-1')).called(1);
  });
}
