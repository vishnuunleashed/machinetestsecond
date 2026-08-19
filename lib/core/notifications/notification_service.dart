import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Generic, feature-agnostic notification display. Knows nothing about
/// tasks — `features/tasks` owns the policy of *when* to notify (see
/// `TaskDueNotificationPoller`); this just shows a notification right now.
///
/// Deliberately fire-now rather than OS-scheduled: `zonedSchedule` (AlarmManager
/// + timezone data) proved unreliable across devices in practice, so a
/// poller checks due tasks on an interval and calls [showNow] the moment
/// one is actually due — trading "works even if the app is fully closed"
/// for "actually fires reliably while the app is running."
abstract class NotificationService {
  /// Must be called once before [showNow] is used. [onTap] fires with the
  /// notification's payload when the user taps a notification while the
  /// app is running or backgrounded.
  Future<void> initialize({required void Function(String payload) onTap});

  /// If the app was cold-started by tapping a notification (fully
  /// terminated beforehand), returns that notification's payload — checked
  /// once at startup since [onTap] alone only covers the running/
  /// backgrounded cases.
  Future<String?> consumeLaunchPayload();

  /// Requests the Android 13+ notification permission. Returns whether it
  /// was granted; callers should degrade gracefully (no crash, reminders
  /// silently don't fire) if false.
  Future<bool> requestPermission();

  /// Shows a notification immediately.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  });
}

class LocalNotificationServiceImpl implements NotificationService {
  static const _channelId = 'task_reminders';
  static const _channelName = 'Task Reminders';
  static const _channelDescription = 'Notifications for tasks that are due';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize({required void Function(String payload) onTap}) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) onTap(payload);
      },
    );
  }

  @override
  Future<String?> consumeLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details!.notificationResponse?.payload;
  }

  @override
  Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission();
    return granted ?? false;
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    // A failure here must never break whatever caller triggered it — see
    // TaskDueNotificationPoller, which calls this outside its own try/catch.
    try {
      debugPrint('NotificationService: showing id=$id "$title"');
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    } catch (e, st) {
      debugPrint('NotificationService: FAILED to show id=$id: $e\n$st');
    }
  }
}
