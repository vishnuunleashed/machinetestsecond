import '../../../../core/usecase/stream_usecase.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/task_repository.dart';

class WatchSyncStatus implements StreamUseCase<bool, NoParams> {
  final TaskRepository repository;

  const WatchSyncStatus(this.repository);

  @override
  Stream<bool> call(NoParams params) => repository.isSyncing;
}
