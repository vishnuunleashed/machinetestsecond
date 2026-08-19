import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  /// Emits the current user on every sign-in/sign-out, and once immediately
  /// on subscription with whatever the current state is.
  Stream<AppUser?> watchAuthState();

  Future<Either<Failure, AppUser>> signIn(String email, String password);

  Future<Either<Failure, AppUser>> signUp(String email, String password);

  Future<Either<Failure, Unit>> signOut();
}
