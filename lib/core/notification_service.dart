import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the daily "come practice" reminder shown when the user turns on
/// the Notifications toggle in Settings. Local-only — no server involved.
class NotificationService {
  NotificationService._();

  /// Shared SharedPreferences key for the Settings "Notifications" toggle.
  static const prefsKey = 'notifications_enabled';

  static const _dailyReminderId = 1;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final deviceTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimezone.identifier));
    } catch (_) {
      // Fall back to whatever tz.local already is (UTC) rather than crash.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Requests OS-level notification permission. Returns whether it was
  /// granted (or was already granted). Safe to call repeatedly.
  static Future<bool> requestPermission() async {
    await init();

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  /// Schedules a recurring daily reminder at [hour]:[minute] local time.
  static Future<void> scheduleDailyReminder({int hour = 19, int minute = 0}) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Practice Reminder',
      channelDescription: "Reminds you to practice your Arabic if you haven't today.",
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Time to practice! 🌱',
      "Keep your streak going — review a few words or take today's quiz.",
      _nextInstanceOf(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Fires an immediate notification so the toggle can be verified without
  /// waiting for the actual scheduled hour.
  static Future<void> showTestNotification() async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Practice Reminder',
      channelDescription: "Reminds you to practice your Arabic if you haven't today.",
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _plugin.show(0, 'Test notification', 'Notifications are working! 🎉', details);
  }

  static Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(_dailyReminderId);
  }

  /// Re-applies the persisted toggle state to the OS-level schedule. Call
  /// once at app startup so a reinstall/update doesn't silently lose the
  /// reminder even though the preference still says it's on. Does not
  /// (re-)request permission — that only happens when the user flips the
  /// toggle in Settings.
  static Future<void> syncFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(prefsKey) ?? true;
    if (enabled) {
      await scheduleDailyReminder();
    } else {
      await cancelDailyReminder();
    }
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
