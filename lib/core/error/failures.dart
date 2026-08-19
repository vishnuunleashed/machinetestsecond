import 'package:equatable/equatable.dart';

/// Base type returned on the `Left` side of every repository/usecase call.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to read local cache']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Failed to reach server']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Not authenticated']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong']);
}
