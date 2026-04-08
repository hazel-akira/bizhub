import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SalesReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const SalesReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });
}

class SalesReminderService {
  SalesReminderService._();
  static final SalesReminderService instance = SalesReminderService._();

  static const int _notificationId = 5001;
  static const _enabledKey = 'sales_reminder_enabled';
  static const _hourKey = 'sales_reminder_hour';
  static const _minuteKey = 'sales_reminder_minute';
  static const _defaultHour = 19;
  static const _defaultMinute = 0;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const linuxInit = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        linux: linuxInit,
      ),
    );

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    _initialized = true;
  }

  Future<SalesReminderSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final rawHour = prefs.getInt(_hourKey);
    final rawMinute = prefs.getInt(_minuteKey);
    final safeHour =
        (rawHour != null && rawHour >= 0 && rawHour <= 23) ? rawHour : _defaultHour;
    final safeMinute = (rawMinute != null && rawMinute >= 0 && rawMinute <= 59)
        ? rawMinute
        : _defaultMinute;

    return SalesReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? true,
      hour: safeHour,
      minute: safeMinute,
    );
  }

  Future<void> saveSettings(SalesReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_hourKey, settings.hour);
    await prefs.setInt(_minuteKey, settings.minute);
  }

  Future<void> syncDailyReminder({required bool hasSalesToday}) async {
    await initialize();
    final settings = await getSettings();

    if (!settings.enabled || hasSalesToday) {
      await _plugin.cancel(id: _notificationId);
      return;
    }

    final now = DateTime.now();
    var target = DateTime(
      now.year,
      now.month,
      now.day,
      settings.hour,
      settings.minute,
    );
    if (now.isAfter(target)) {
      target = target.add(const Duration(days: 1));
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sales_reminder_channel',
        'Sales reminders',
        channelDescription: 'Reminds you to record sales each day',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      linux: const LinuxNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Record today\'s sales',
      body: 'No sales recorded yet. Add your sales before day ends.',
      scheduledDate: tz.TZDateTime.from(target, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

