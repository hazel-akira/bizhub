import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class GroupPostReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;
  final String groupInviteUrl;

  const GroupPostReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.groupInviteUrl,
  });
}

/// Schedules a daily reminder to open the app and copy the generated WhatsApp group post.
class GroupPostReminderService {
  GroupPostReminderService._();
  static final GroupPostReminderService instance = GroupPostReminderService._();

  static const int _notificationId = 5002;
  static const _enabledKey = 'group_post_reminder_enabled';
  static const _hourKey = 'group_post_reminder_hour';
  static const _minuteKey = 'group_post_reminder_minute';
  static const _groupUrlKey = 'group_post_reminder_invite_url';
  static const _defaultHour = 8;
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

  Future<GroupPostReminderSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final rawHour = prefs.getInt(_hourKey);
    final rawMinute = prefs.getInt(_minuteKey);
    final safeHour =
        (rawHour != null && rawHour >= 0 && rawHour <= 23) ? rawHour : _defaultHour;
    final safeMinute = (rawMinute != null && rawMinute >= 0 && rawMinute <= 59)
        ? rawMinute
        : _defaultMinute;

    return GroupPostReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      hour: safeHour,
      minute: safeMinute,
      groupInviteUrl: (prefs.getString(_groupUrlKey) ?? '').trim(),
    );
  }

  Future<void> saveSettings(GroupPostReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_hourKey, settings.hour);
    await prefs.setInt(_minuteKey, settings.minute);
    await prefs.setString(_groupUrlKey, settings.groupInviteUrl.trim());
  }

  Future<void> syncDailyReminder() async {
    await initialize();
    final settings = await getSettings();

    if (!settings.enabled) {
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
        'whatsapp_group_post_channel',
        'WhatsApp group posts',
        channelDescription:
            'Daily reminder to copy your AI-style group message into WhatsApp',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
      linux: const LinuxNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Daily WhatsApp group message',
      body:
          'Open BizHub → Assistant → Daily group post to copy today\'s message.',
      scheduledDate: tz.TZDateTime.from(target, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
