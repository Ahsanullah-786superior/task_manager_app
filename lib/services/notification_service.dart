import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../models/task.dart';

/// Handles local notifications that remind the user about tasks nearing
/// their due date.
///
/// NOTE: This uses on-device scheduled local notifications, which fire even
/// without a network connection or backend. This satisfies "notify the user
/// before a task is due" without needing a server.
///
/// For true server-triggered push notifications (e.g. notifying a user even
/// if the app was deleted and reinstalled, or cross-device sync of reminders),
/// pair this with a Firebase Cloud Function that watches the `tasks`
/// collection and sends messages via Firebase Cloud Messaging (FCM). See the
/// README for a sample Cloud Function.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Android 13+ requires runtime notification permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Deterministic int ids derived from the task id so we can target
  /// specific notifications for cancellation later.
  int _dayBeforeId(String taskId) => taskId.hashCode & 0x7FFFFFFF;
  int _dueNowId(String taskId) => (taskId.hashCode ^ 0x5A5A5A) & 0x7FFFFFFF;

  Future<void> scheduleTaskReminders(Task task) async {
    if (!_initialized) await init();

    final now = DateTime.now();

    // Reminder 1 day before due date.
    final dayBefore = task.dueDate.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(now)) {
      await _schedule(
        id: _dayBeforeId(task.id),
        title: 'Task due tomorrow',
        body: '"${task.title}" is due tomorrow.',
        scheduledDate: dayBefore,
      );
    }

    // Reminder at the due date/time itself.
    if (task.dueDate.isAfter(now)) {
      await _schedule(
        id: _dueNowId(task.id),
        title: 'Task due now',
        body: '"${task.title}" is due now.',
        scheduledDate: task.dueDate,
      );
    }
  }

  Future<void> cancelTaskReminders(String taskId) async {
    await _plugin.cancel(_dayBeforeId(taskId));
    await _plugin.cancel(_dueNowId(taskId));
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_due_channel',
      'Task Due Reminders',
      channelDescription: 'Reminders for tasks nearing their due date',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
