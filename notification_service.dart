import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Handles device (push-style) reminders using local scheduled notifications.
/// Works offline and needs no server / paid Firebase plan.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'petcarehub_reminders',
      'Pet care reminders',
      channelDescription: 'Appointment and vaccination reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  /// Android 13+ asks the user for permission to show notifications.
  static Future<void> requestPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  /// Stable numeric id from a Firestore document id.
  static int idFor(String key) {
    int hash = 0x811c9dc5;
    for (final c in key.codeUnits) {
      hash ^= c;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static Future<void> showNow(String key, String title, String body) async {
    try {
      await _plugin.show(idFor('now_$key'), title, body, _details);
    } catch (e) {
      debugPrint('Show notification failed: $e');
    }
  }

  static Future<void> schedule({
    required String key,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        idFor(key),
        title,
        body,
        tz.TZDateTime.from(when.toUtc(), tz.UTC),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Schedule notification failed: $e');
    }
  }

  static Future<void> cancel(String key) async {
    try {
      await _plugin.cancel(idFor(key));
    } catch (e) {
      debugPrint('Cancel notification failed: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
