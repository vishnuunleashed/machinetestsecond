import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/watch_auth_state.dart';

/// The single source of truth for "is anyone signed in" — the root widget
/// (`AuthGate` in main.dart) watches this to decide Login vs. Task List.
/// Deliberately not folded into [AuthFormNotifier]: signing in doesn't need
/// to manually navigate, this stream reacting is what does that.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return sl<WatchAuthState>()(const NoParams());
});
