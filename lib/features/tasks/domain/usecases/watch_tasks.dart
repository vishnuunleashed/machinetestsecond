import '../../../../core/usecase/stream_usecase.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class WatchTasks implements StreamUseCase<List<TaskEntity>, NoParams> {
  final TaskRepository repository;

  const WatchTasks(this.repository);

  @override
  Stream<List<TaskEntity>> call(NoParams params) {
    return repository.watchTasks();
  }
}
