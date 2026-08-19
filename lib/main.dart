import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/injection_container.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_notifier.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_state_provider.dart';
import 'features/tasks/data/datasources/task_local_data_source.dart';
import 'features/tasks/domain/entities/task_entity.dart';
import 'features/tasks/presentation/pages/task_details_page.dart';
import 'features/tasks/presentation/pages/task_list_page.dart';

/// A notification tap can cold-start the app with no widget tree to
/// navigate from yet, so navigation goes through this key instead of a
/// BuildContext.
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initDependencies();

  final notificationService = sl<NotificationService>();
  await notificationService.initialize(onTap: _openTaskFromNotification);
  final permissionGranted = await notificationService.requestPermission();
  debugPrint('Notification permission granted: $permissionGranted');

  final launchPayload = await notificationService.consumeLaunchPayload();
  if (launchPayload != null) {
    // Defer until the widget tree (and navigatorKey) actually exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openTaskFromNotification(launchPayload);
    });
  }

  runApp(const ProviderScope(child: MyApp()));
}

/// Looks up the tapped notification's task by id and pushes its details
/// screen. If the task's gone (e.g. deleted since the reminder fired),
/// this just does nothing rather than erroring.
Future<void> _openTaskFromNotification(String taskId) async {
  final tasks = await sl<TaskLocalDataSource>().getAllTasks();
  TaskEntity? task;
  for (final t in tasks) {
    if (t.id == taskId) {
      task = t;
      break;
    }
  }
  if (task == null) return;
  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => TaskDetailsPage(task: task!)),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp(
      title: 'Task Manager',
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

/// Decides Login vs. Task List by watching Firebase's own auth stream
/// (via `authStateProvider`) — signing in/out doesn't need manual
/// navigation, this widget reacts to the stream automatically.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (user) => user == null ? const LoginPage() : const TaskListPage(),
    );
  }
}
