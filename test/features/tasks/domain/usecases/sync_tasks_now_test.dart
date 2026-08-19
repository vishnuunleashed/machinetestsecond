import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:machinetestsecond/core/usecase/usecase.dart';
import 'package:machinetestsecond/features/tasks/domain/repositories/task_repository.dart';
import 'package:machinetestsecond/features/tasks/domain/usecases/sync_tasks_now.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repository;
  late SyncTasksNow usecase;

  setUp(() {
    repository = MockTaskRepository();
    usecase = SyncTasksNow(repository);
  });

  test('delegates to repository.syncNow', () async {
    when(() => repository.syncNow()).thenAnswer((_) async => const Right(unit));

    final result = await usecase(const NoParams());

    expect(result, const Right(unit));
    verify(() => repository.syncNow()).called(1);
  });
}
