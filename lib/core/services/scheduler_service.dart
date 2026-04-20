import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_config.dart';
import 'notification_service.dart';

class SchedulerService {
  SchedulerService._();
  static final SchedulerService instance = SchedulerService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _bellChannel = MethodChannel('attend/bells');

  static const _gathaNotifId = 2000;

  // ── Mindfulness bells ─────────────────────────────────────────────────────

  /// Ensures the per-sound notification channel exists, then delegates all
  /// alarm scheduling to the native BellSchedulerReceiver. That receiver
  /// schedules 30 days of bells and arms a 25-day sentinel that re-invokes
  /// itself — no app open required for ongoing delivery.
  Future<void> rescheduleBells(NotificationConfig config) async {
    if (!config.enabled) {
      await cancelAllBells();
      return;
    }
    await NotificationService.instance.ensureMindfulnessChannel(config.bellSoundId);
    try {
      await _bellChannel.invokeMethod<void>('triggerReschedule');
      debugPrint('Attend: native bell reschedule triggered');
    } catch (e) {
      debugPrint('Attend: FAILED to trigger native bell reschedule: $e');
      rethrow;
    }
  }

  Future<void> cancelAllBells() async {
    try {
      await _bellChannel.invokeMethod<void>('cancelScheduler');
    } catch (e) {
      debugPrint('Attend: cancelAllBells error: $e');
    }
  }

  /// Schedules a single test bell [secondsFromNow] seconds in the future.
  Future<void> scheduleTestBell({
    required String soundId,
    int secondsFromNow = 10,
  }) async {
    await NotificationService.instance.ensureMindfulnessChannel(soundId);
    final dt = DateTime.now().add(Duration(seconds: secondsFromNow));
    final channelId = 'mindfulness_bell_v2_$soundId';
    debugPrint('Attend: scheduling TEST bell at $dt ($secondsFromNow s from now)');
    try {
      await _bellChannel.invokeMethod<void>('scheduleBell', {
        'id': 998,
        'epochMs': dt.millisecondsSinceEpoch,
        'channelId': channelId,
      });
    } catch (e) {
      debugPrint('Attend: FAILED to schedule test bell: $e');
      rethrow;
    }
  }

  // ── Daily gatha notification ──────────────────────────────────────────────

  Future<void> scheduleDailyGatha(NotificationConfig config) async {
    await cancelDailyGatha();
    if (!config.dailyGathaEnabled) return;

    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, config.dailyGathaHour);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    final (title, firstLine) = await _gathaForDate(target);

    await _plugin.zonedSchedule(
      _gathaNotifId,
      title,
      firstLine,
      tz.TZDateTime.from(target, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_gatha',
          'Daily poem',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          autoCancel: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // ignore: deprecated_member_use
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelDailyGatha() async {
    await _plugin.cancel(_gathaNotifId);
  }

  Future<(String, String)> _gathaForDate(DateTime date) async {
    try {
      final raw = await rootBundle.loadString('assets/data/gathas.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final gathas =
          (json['gathas'] as List<dynamic>).cast<Map<String, dynamic>>();
      final epoch = DateTime(2026, 1, 1);
      final index = date.difference(epoch).inDays.abs() % gathas.length;
      final g = gathas[index];
      final title = g['title'] as String;
      final body = g['body'] as String;
      final firstLine = body
          .split('\n')
          .map((l) => l.trim())
          .firstWhere((l) => l.isNotEmpty, orElse: () => '');
      return (title, firstLine);
    } catch (_) {
      return ('Poem of the day', 'A moment of mindfulness awaits.');
    }
  }
}
