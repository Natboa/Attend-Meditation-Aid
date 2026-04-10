import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_config.dart';
import 'notification_service.dart';

class SchedulerService {
  SchedulerService._();
  static final SchedulerService instance = SchedulerService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Notification IDs 1000–1019 are reserved for scheduled bells.
  static const _bellBaseId = 1000;
  static const _maxBells = 20;

  /// Computes [config.frequencyPerDay] random [DateTime]s within
  /// [config.startHour, config.endHour) for [date], if [date]'s weekday
  /// is in [config.activeDays]. Returns empty list otherwise.
  List<DateTime> computeRandomTimes(NotificationConfig config, DateTime date) {
    if (!config.activeDays.contains(date.weekday)) return [];

    final startMs = DateTime(date.year, date.month, date.day, config.startHour)
        .millisecondsSinceEpoch;
    final endMs = DateTime(date.year, date.month, date.day, config.endHour)
        .millisecondsSinceEpoch;

    if (endMs <= startMs) return [];

    final rangeMs = endMs - startMs;
    final rng = Random();
    return List.generate(config.frequencyPerDay, (_) {
      final offset = rng.nextInt(rangeMs);
      return DateTime.fromMillisecondsSinceEpoch(startMs + offset);
    })..sort();
  }

  /// Cancels all pending bells, then schedules new ones based on [config].
  Future<void> rescheduleBells(NotificationConfig config) async {
    await cancelAllBells();
    if (!config.enabled) return;

    await NotificationService.instance
        .ensureMindfulnessChannel(config.bellSoundId);

    final now = DateTime.now();
    int idCursor = 0;

    // Today's remaining bells
    final todayTimes = computeRandomTimes(config, now)
        .where((t) => t.isAfter(now))
        .toList();

    for (final t in todayTimes) {
      if (idCursor >= _maxBells) break;
      await _scheduleOne(_bellBaseId + idCursor, t, config.bellSoundId);
      idCursor++;
    }

    // If today is empty or nearly full, schedule the next eligible day too
    if (idCursor < _maxBells) {
      for (int offset = 1; offset <= 7; offset++) {
        final candidate = DateTime(now.year, now.month, now.day + offset);
        final times = computeRandomTimes(config, candidate);
        if (times.isEmpty) continue;
        for (final t in times) {
          if (idCursor >= _maxBells) break;
          await _scheduleOne(_bellBaseId + idCursor, t, config.bellSoundId);
          idCursor++;
        }
        break; // only schedule one future day
      }
    }
  }

  Future<void> _scheduleOne(int id, DateTime dt, String soundId) async {
    final tzDt = tz.TZDateTime.from(dt, tz.local);
    final androidDetails = AndroidNotificationDetails(
      'mindfulness_bell_$soundId',
      'Mindfulness bell',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      ongoing: false,
      silent: false,
      styleInformation: const BigTextStyleInformation(''),
    );

    await _plugin.zonedSchedule(
      id,
      null,
      null,
      tzDt,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // ignore: deprecated_member_use
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAllBells() async {
    for (int i = 0; i < _maxBells; i++) {
      await _plugin.cancel(_bellBaseId + i);
    }
  }
}
