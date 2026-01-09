import 'dart:io';
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
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return; // Prevent double initialization
    
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await _getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Timezone initialized: $timeZoneName');

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_notification');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      _isInitialized = true;
      debugPrint('Notification Plugin initialized');

    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      // Ensure initialized first
      if (!_isInitialized) {
        await init();
      }

      if (Platform.isAndroid) {
        final androidImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          debugPrint('Requesting Android notification permissions...');
          
          // Request notification permission (Android 13+)
          final bool? notificationGranted = await androidImplementation.requestNotificationsPermission();
          debugPrint('Notification Permission result: $notificationGranted');
          
          // Also request exact alarm permission (Android 12+)
          final bool? exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
          debugPrint('Exact Alarm Permission result: $exactAlarmGranted');
          
          return (notificationGranted ?? false);
        } else {
          debugPrint('AndroidFlutterLocalNotificationsPlugin implementation NOT found!');
          return false;
        }
      } else if (Platform.isIOS) {
        final iosImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImplementation != null) {
          final bool? granted = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
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
      // Ensure initialized
      if (!_isInitialized) {
        await init();
      }

      final scheduledDate = _nextInstanceOfTime(time);
      debugPrint('Scheduling notification for: $scheduledDate');

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0, // Notification ID
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
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
      );
      debugPrint('Notification scheduled successfully for ${time.hour}:${time.minute}');
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
      if (Platform.isAndroid) {
        final String? timeZone = await _channel.invokeMethod('getLocalTimezone');
        if (timeZone != null) return timeZone;
      }
    } catch (e) {
      debugPrint('Failed to get native timezone: $e');
    }
    return 'UTC'; // Fallback
  }
}
