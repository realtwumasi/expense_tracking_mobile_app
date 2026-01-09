import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final MethodChannel _channel = const MethodChannel('antigravity/timezone');

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await _getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Timezone initialized: $timeZoneName');

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsDarwin =
          const DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      debugPrint('Notification Plugin initialized');
      
      // Request permissions immediately on init as per user requirement
      await requestPermissions();

    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (ThemeMode.system == ThemeMode.system) { 
        final androidImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          debugPrint('Requesting Android notification permissions...');
          final bool? granted = await androidImplementation.requestNotificationsPermission();
          debugPrint('Notification Permission result: $granted');
          return granted ?? false;
        } else {
          debugPrint('AndroidFlutterLocalNotificationsPlugin implementation NOT founded!');
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> scheduleDailyNotification(TimeOfDay time) async {
    try {
      final scheduledDate = _nextInstanceOfTime(time);
      debugPrint('Scheduling notification for: $scheduledDate');

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Expense Tracker Reminder',
        'Don\'t forget to log your expenses for today!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_expense_reminder',
            'Daily Reminder',
            channelDescription: 'Reminds you to log daily expenses',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Notification scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('All notifications cancelled');
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<String> _getLocalTimezone() async {
    try {
      if (ThemeMode.system == ThemeMode.system) { // Dummy check to satisfy linter if needed, mostly platform check
        // For Android:
         final String? timeZone = await _channel.invokeMethod('getLocalTimezone');
         if (timeZone != null) return timeZone;
      }
    } catch (e) {
      debugPrint('Failed to get native timezone: $e');
    }
    return 'UTC'; // Fallback
  }
}
