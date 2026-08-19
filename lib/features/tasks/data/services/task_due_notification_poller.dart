import 'dart:async';

import '../../../../core/notifications/notification_service.dart';
import '../../domain/entities/task_entity.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

/// Checks locally-held tasks on an interval and fires a notification the
/// moment one becomes due — see `NotificationService` for why this exists
/// instead of an OS-scheduled alarm. Fully decoupled from write paths: it
/// doesn't need to be told when a task changes, it just re-scans.
///
/// Trade-off: only fires while this poller is running, i.e. while the app
/// process is alive (foreground or backgrounded-but-not-killed). It cannot
/// wake up a fully terminated app the way an OS-level alarm can.
class TaskDueNotificationPoller {
  static const _pollInterval = Duration(seconds: 30);

  final TaskLocalDataSource local;
  final NotificationService notificationService;

  Timer? _timer;

  TaskDueNotificationPoller({
    required this.local,
    required this.notificationService,
  });

  void start() {
    checkNow();
    _timer = Timer.periodic(_pollInterval, (_) => checkNow());
  }

  void dispose() => _timer?.cancel();

  int _idFor(String taskId) => taskId.hashCode & 0x7fffffff;

  /// Scans all local tasks once and notifies any that just became due.
  /// Public (rather than private) so tests can drive it deterministically
  /// instead of waiting on the real [_pollInterval].
  Future<void> checkNow() async {
    final tasks = await local.getAllTasks();
    final now = DateTime.now();

    for (final task in tasks) {
      final isDue = !task.isCompleted &&
          task.syncStatus != SyncStatus.pendingDelete &&
          !task.notified &&
          !task.dueDate.isAfter(now);
      if (!isDue) continue;

      await notificationService.showNow(
        id: _idFor(task.id),
        title: 'Task due: ${task.title}',
        body: _bodyFor(task),
        payload: task.id,
      );
      await local.upsertTask(task.copyWithNotified(true));
    }
  }

  String _bodyFor(TaskModel task) {
    final priorityLabel = '${task.priority.label} priority';
    return task.description.isEmpty
        ? '$priorityLabel · Tap to view details'
        : '$priorityLabel · ${task.description}';
  }
}
