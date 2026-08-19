import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import 'email_password_params.dart';

class SignUp implements UseCase<AppUser, EmailPasswordParams> {
  final AuthRepository repository;

  const SignUp(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(EmailPasswordParams params) {
    return repository.signUp(params.email, params.password);
  }
}
