import 'package:equatable/equatable.dart';

/// Pure domain object for the signed-in user — no knowledge of
/// firebase_auth's `User` type.
class AppUser extends Equatable {
  final String uid;
  final String email;

  const AppUser({required this.uid, required this.email});

  @override
  List<Object?> get props => [uid, email];
}
