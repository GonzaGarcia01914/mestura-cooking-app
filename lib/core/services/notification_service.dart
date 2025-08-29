import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // Timezone db
    try {
      tzdata.initializeTimeZones();
      // tz.setLocalLocation(...) no requerido si usamos tz.local
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[NotificationService] TZ init error: $e');
      }
    }

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosInit =
        const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  static const String _channelId = 'cooking_timers';
  static const String _channelName = 'Cooking Timers';
  static const String _channelDesc = 'Timers for cooking steps';
  static const String _ongoingChannelId = 'cooking_countdown';
  static const String _ongoingChannelName = 'Cooking Countdown';
  static const String _ongoingChannelDesc = 'Ongoing countdown while cooking';

  static NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    return const NotificationDetails(android: android, iOS: ios);
  }

  static NotificationDetails _ongoingDetails({required int whenEpochMs}) {
    final android = AndroidNotificationDetails(
      _ongoingChannelId,
      _ongoingChannelName,
      channelDescription: _ongoingChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true,
      onlyAlertOnce: true,
      showWhen: true,
      when: whenEpochMs,
      usesChronometer: true,
      chronometerCountDown: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: false,
      presentSound: false,
      presentBadge: false,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  /// Programa una alarma en [when]. Devuelve el ID asignado.
  static Future<int> scheduleAlarm({
    required DateTime when,
    required String title,
    required String body,
    int? id,
  }) async {
    await init();
    final notifId = id ?? Random().nextInt(1 << 31);
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      notifId,
      title,
      body,
      tzWhen,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'timer',
      matchDateTimeComponents: null,
    );
    return notifId;
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  static const int _ongoingId = 424242;

  static Future<void> showOngoingCountdown({
    required DateTime endsAt,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      _ongoingId,
      title,
      body,
      _ongoingDetails(whenEpochMs: endsAt.millisecondsSinceEpoch),
      payload: 'ongoing_timer',
    );
  }

  static Future<void> cancelOngoingCountdown() async {
    await _plugin.cancel(_ongoingId);
  }
}
