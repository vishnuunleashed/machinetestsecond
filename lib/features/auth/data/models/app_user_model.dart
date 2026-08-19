import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({required super.uid, required super.email});

  factory AppUserModel.fromFirebaseUser(fb.User user) {
    return AppUserModel(uid: user.uid, email: user.email ?? '');
  }
}
