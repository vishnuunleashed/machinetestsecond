import '../../../../core/usecase/stream_usecase.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class WatchAuthState implements StreamUseCase<AppUser?, NoParams> {
  final AuthRepository repository;

  const WatchAuthState(this.repository);

  @override
  Stream<AppUser?> call(NoParams params) => repository.watchAuthState();
}
