import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'timer_done',
      'Timer finished',
      channelDescription: 'Alerts when a timer reaches zero',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    tz.initializeTimeZones();
    final localZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localZone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  Future<void> schedule({
    required int id,
    required String title,
    required DateTime when,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: 'Time is up',
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
