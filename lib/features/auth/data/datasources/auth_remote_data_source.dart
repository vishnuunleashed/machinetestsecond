import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exceptions.dart';
import '../models/app_user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<AppUserModel?> watchAuthState();

  Future<AppUserModel> signIn(String email, String password);

  Future<AppUserModel> signUp(String email, String password);

  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  @override
  Stream<AppUserModel?> watchAuthState() {
    return firebaseAuth.authStateChanges().map(
          (user) => user == null ? null : AppUserModel.fromFirebaseUser(user),
        );
  }

  @override
  Future<AppUserModel> signIn(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const ServerException('Sign in failed.');
      return AppUserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw ServerException(_messageFor(e));
    }
  }

  @override
  Future<AppUserModel> signUp(String email, String password) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const ServerException('Sign up failed.');
      return AppUserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw ServerException(_messageFor(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
