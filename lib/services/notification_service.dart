import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/future_message.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String channelId = 'unlock_channel';
  static const String channelName = 'Message unlocks';
  static const String channelDescription =
      'Notifications when a sealed message unlocks.';
  static const String _exactAlarmAskedKey = 'exact_alarm_requested';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static int notificationIdFor(String messageId) =>
      messageId.hashCode & 0x7fffffff;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      try {
      final timeZoneName =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        debugPrint('NotificationService: using default time zone ($e)');
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );
      await _plugin.initialize(settings: settings);

      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('NotificationService: init failed ($e)');
    } finally {
      _initialized = true;
    }
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    try {
      final prefs = await SharedPreferences.getInstance();
      final askedExact = prefs.getBool(_exactAlarmAskedKey) ?? false;
      if (!askedExact) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestExactAlarmsPermission();
        await prefs.setBool(_exactAlarmAskedKey, true);
      }
    } catch (e) {
      debugPrint('NotificationService: exact alarm request failed ($e)');
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleUnlock(FutureMessage message) async {
    if (!message.unlockAt.isAfter(DateTime.now())) return;
    if (!_initialized) await init();

    final scheduledDate = tz.TZDateTime.from(message.unlockAt, tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
      ),
    );

    var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (await android?.canScheduleExactNotifications() == true) {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (e) {
      debugPrint('NotificationService: exact alarm check failed ($e)');
    }

    try {
      await _plugin.zonedSchedule(
        id: notificationIdFor(message.id),
        title: 'A message from your past self',
        body: 'Your note is ready to open.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
        payload: message.id,
      );
    } catch (e) {
      debugPrint('NotificationService: schedule failed ($e)');
      if (scheduleMode != AndroidScheduleMode.inexactAllowWhileIdle) {
        try {
          await _plugin.zonedSchedule(
            id: notificationIdFor(message.id),
            title: 'A message from your past self',
            body: 'Your note is ready to open.',
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: message.id,
          );
        } catch (e) {
          debugPrint('NotificationService: inexact schedule failed ($e)');
        }
      }
    }
  }

  Future<void> cancel(String messageId) async {
    try {
      await _plugin.cancel(id: notificationIdFor(messageId));
    } catch (e) {
      debugPrint('NotificationService: cancel failed ($e)');
    }
  }
}
