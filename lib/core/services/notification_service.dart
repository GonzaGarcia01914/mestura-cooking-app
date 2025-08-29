import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
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

    // Android 13+: solicita permiso de notificaciones si es necesario
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    } catch (_) {}
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
    bool preferExact = true,
  }) async {
    await init();
    final notifId = id ?? Random().nextInt(1 << 31);
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        tzWhen,
        _notificationDetails(),
        androidScheduleMode:
            preferExact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'timer',
        matchDateTimeComponents: null,
      );
    } catch (e) {
      final msg = e.toString();
      final needsExactPerm = msg.contains('exact_alarms_not_permitted');
      if (needsExactPerm && preferExact) {
        // Intenta abrir ajustes para conceder "Alarms & reminders" y reenviar inexacto
        await openExactAlarmsSettings();
        try {
          await _plugin.zonedSchedule(
            notifId,
            title,
            body,
            tzWhen,
            _notificationDetails(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'timer',
            matchDateTimeComponents: null,
          );
        } catch (_) {}
      }
    }
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

  static Future<void> openExactAlarmsSettings() async {
    if (!Platform.isAndroid) return;
    // Android 12+: abre la pantalla "Alarms & reminders"
    const intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    );
    try {
      await intent.launch();
    } catch (_) {}
  }
}
