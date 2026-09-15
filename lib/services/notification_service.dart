import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationCopy {
  const NotificationCopy({
    required this.dailyTitle,
    required this.dailyBody,
    required this.streakTitle,
    required this.streakBody,
  });

  final String dailyTitle;
  final String dailyBody;
  final String streakTitle;
  final String streakBody;

  factory NotificationCopy.forLocale(String locale) => switch (locale) {
        'ru' => const NotificationCopy(
            dailyTitle: 'Ежедневное испытание',
            dailyBody: 'Новое задание Tash Rush уже ждёт вас.',
            streakTitle: 'Сохраните серию',
            streakBody: 'Зайдите сегодня, чтобы продолжить ежедневную серию.',
          ),
        'ky' => const NotificationCopy(
            dailyTitle: 'Күнүмдүк тапшырма',
            dailyBody: 'Tash Rush оюнунда жаңы тапшырма даяр.',
            streakTitle: 'Серияны сактаңыз',
            streakBody: 'Күнүмдүк серияны улантуу үчүн бүгүн ойноңуз.',
          ),
        _ => const NotificationCopy(
            dailyTitle: 'Daily Challenge',
            dailyBody: 'A new Tash Rush challenge is ready for you.',
            streakTitle: 'Keep your streak',
            streakBody: 'Play today to continue your daily streak.',
          ),
      };
}

abstract interface class NotificationGateway {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> cancel(int id);
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  });
}

class FlutterNotificationGateway implements NotificationGateway {
  FlutterNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      // UTC remains a safe fallback if a platform cannot expose its timezone.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily reminders',
          channelDescription: 'Daily challenge and streak reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

class NotificationService {
  NotificationService(this._gateway);

  static const dailyChallengeId = 1001;
  static const streakId = 1002;
  final NotificationGateway _gateway;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _gateway.initialize();
    _initialized = true;
  }

  Future<bool> setEnabled(
    bool enabled,
    String locale, {
    bool requestPermission = true,
  }) async {
    await initialize();
    await _cancelOwnedNotifications();
    if (!enabled) return true;
    if (requestPermission && !await _gateway.requestPermission()) return false;
    final copy = NotificationCopy.forLocale(locale);
    await _gateway.scheduleDaily(
      id: dailyChallengeId,
      hour: 18,
      minute: 30,
      title: copy.dailyTitle,
      body: copy.dailyBody,
    );
    await _gateway.scheduleDaily(
      id: streakId,
      hour: 21,
      minute: 0,
      title: copy.streakTitle,
      body: copy.streakBody,
    );
    return true;
  }

  Future<void> _cancelOwnedNotifications() => Future.wait([
        _gateway.cancel(dailyChallengeId),
        _gateway.cancel(streakId),
      ]);
}

class NoopNotificationGateway implements NotificationGateway {
  const NoopNotificationGateway();

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {}
}
