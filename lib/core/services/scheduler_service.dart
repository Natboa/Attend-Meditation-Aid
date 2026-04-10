import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
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

  /// Notification ID for the daily gatha.
  static const _gathaNotifId = 2000;

  // ── Mindfulness bells ─────────────────────────────────────────────────────

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
      await _scheduleBell(_bellBaseId + idCursor, t, config.bellSoundId);
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
          await _scheduleBell(_bellBaseId + idCursor, t, config.bellSoundId);
          idCursor++;
        }
        break;
      }
    }
  }

  Future<void> _scheduleBell(int id, DateTime dt, String soundId) async {
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

  // ── Daily gatha notification ──────────────────────────────────────────────

  /// Schedules a single daily gatha notification at [config.dailyGathaHour].
  /// Call this from both the UI (when user enables/changes hour) and the
  /// WorkManager background task (to refresh content for the next day).
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

  /// Loads the gatha for [date] using the same deterministic algorithm as
  /// [GathaRepository.gathaOfTheDay]. Returns (title, firstNonEmptyLine).
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
