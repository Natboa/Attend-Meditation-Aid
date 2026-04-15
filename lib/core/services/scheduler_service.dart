import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // MethodChannel + rootBundle
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_config.dart';
import 'notification_service.dart';

class SchedulerService {
  SchedulerService._();
  static final SchedulerService instance = SchedulerService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Native channel — schedules/cancels AlarmManager alarms for mindfulness bells.
  /// Handled by BellPlugin (registered in GeneratedPluginRegistrant) so it works
  /// in both foreground and background (WorkManager) contexts.
  static const _bellChannel = MethodChannel('attend/bells');

  /// Notification IDs 1000–1019 are reserved for scheduled bells.
  static const _bellBaseId = 1000;
  static const _maxBells = 20;

  /// Notification ID for the daily gatha.
  static const _gathaNotifId = 2000;

  /// Minimum gap between consecutive bells (30 minutes).
  static const _minBellGapMs = 30 * 60 * 1000;

  static const _todayBellsKey = 'today_bell_times';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sharedPrefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<List<DateTime>?> _loadTodayBellTimes() async {
    final prefs = await _sharedPrefs;
    final json = prefs.getString(_todayBellsKey);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (map['date'] != _dateKey(DateTime.now())) return null;
      return (map['times'] as List)
          .map((ms) => DateTime.fromMillisecondsSinceEpoch(ms as int))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveTodayBellTimes(List<DateTime> times) async {
    final prefs = await _sharedPrefs;
    await prefs.setString(
      _todayBellsKey,
      jsonEncode({
        'date': _dateKey(DateTime.now()),
        'times': times.map((t) => t.millisecondsSinceEpoch).toList(),
      }),
    );
  }

  // ── Mindfulness bells ─────────────────────────────────────────────────────

  /// Computes [config.frequencyPerDay] random [DateTime]s within
  /// [config.startHour, config.endHour) for [date], if [date]'s weekday
  /// is in [config.activeDays]. Returns empty list otherwise.
  ///
  /// Uses a jittered-grid strategy: the window is divided into N equal slots
  /// and one time is picked per slot. The jitter within each slot is capped so
  /// that adjacent bells are always at least [_minBellGapMs] apart.
  List<DateTime> computeRandomTimes(NotificationConfig config, DateTime date) {
    if (!config.activeDays.contains(date.weekday)) return [];

    final startMs = DateTime(date.year, date.month, date.day, config.startHour)
        .millisecondsSinceEpoch;
    final endMs = DateTime(date.year, date.month, date.day, config.endHour)
        .millisecondsSinceEpoch;

    if (endMs <= startMs) return [];

    final n = config.frequencyPerDay;
    final rangeMs = endMs - startMs;
    final rng = Random();

    if (n <= 1) {
      return [DateTime.fromMillisecondsSinceEpoch(startMs + rng.nextInt(rangeMs))];
    }

    // Divide the window into n equal slots. Limit jitter per slot so that the
    // minimum gap between adjacent bells is _minBellGapMs:
    //   gap = slotMs + offset_next - offset_curr ≥ slotMs - jitterMs ≥ _minBellGapMs
    //   => jitterMs = max(1, slotMs - _minBellGapMs)
    final slotMs = rangeMs ~/ n;
    final jitterMs = max(1, slotMs - _minBellGapMs);

    return List.generate(n, (i) {
      final slotStart = startMs + i * slotMs;
      return DateTime.fromMillisecondsSinceEpoch(slotStart + rng.nextInt(jitterMs));
    })..sort();
  }

  /// Cancels all pending bells, then schedules new ones based on [config].
  ///
  /// Today's bell times are cached in SharedPreferences so that changing a
  /// setting (e.g. sound) mid-day does not re-roll the random times and lose
  /// bells that were already scheduled for later today.
  Future<void> rescheduleBells(NotificationConfig config) async {
    await cancelAllBells();
    if (!config.enabled) return;

    await NotificationService.instance
        .ensureMindfulnessChannel(config.bellSoundId);

    final now = DateTime.now();
    final windowStart =
        DateTime(now.year, now.month, now.day, config.startHour);
    final windowEnd = DateTime(now.year, now.month, now.day, config.endHour);
    int idCursor = 0;

    // Reuse cached times for today if available; generate and cache otherwise.
    var cachedTimes = await _loadTodayBellTimes();
    if (cachedTimes == null) {
      cachedTimes = computeRandomTimes(config, now);
      await _saveTodayBellTimes(cachedTimes);
    }

    // Keep only future times that still fall within the configured window.
    final todayRemaining = cachedTimes
        .where((t) =>
            t.isAfter(now) &&
            !t.isBefore(windowStart) &&
            t.isBefore(windowEnd))
        .toList();

    debugPrint('Attend: rescheduleBells — today remaining: ${todayRemaining.length}, '
        'cachedTimes: ${cachedTimes.length}, now: $now');

    for (final t in todayRemaining) {
      if (idCursor >= _maxBells) break;
      await _scheduleBell(_bellBaseId + idCursor, t, config.bellSoundId);
      idCursor++;
    }

    // Fill remaining slots from the next eligible day.
    if (idCursor < _maxBells) {
      for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
        final candidate = DateTime(now.year, now.month, now.day + dayOffset);
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

  /// Schedules a bell via BellPlugin / AlarmManager, bypassing flutter_local_notifications'
  /// ScheduledNotificationReceiver which was silently dropped on Samsung One UI / Android 16.
  Future<void> _scheduleBell(int id, DateTime dt, String soundId) async {
    final channelId = 'mindfulness_bell_v2_$soundId';
    final epochMs = dt.millisecondsSinceEpoch;
    try {
      await _bellChannel.invokeMethod<void>('scheduleBell', {
        'id': id,
        'epochMs': epochMs,
        'channelId': channelId,
      });
      debugPrint('Attend: scheduled bell id=$id at $dt soundId=$soundId');
    } catch (e) {
      debugPrint('Attend: FAILED to schedule bell id=$id at $dt: $e');
      rethrow;
    }
  }

  /// Schedules a single test bell [secondsFromNow] seconds in the future.
  /// Useful for verifying that exact-alarm scheduling works end-to-end.
  Future<void> scheduleTestBell({
    required String soundId,
    int secondsFromNow = 10,
  }) async {
    await NotificationService.instance.ensureMindfulnessChannel(soundId);
    final dt = DateTime.now().add(Duration(seconds: secondsFromNow));
    debugPrint('Attend: scheduling TEST bell at $dt ($secondsFromNow s from now)');
    await _scheduleBell(998, dt, soundId);
  }

  Future<void> cancelAllBells() async {
    for (int i = 0; i < _maxBells; i++) {
      try {
        await _bellChannel.invokeMethod<void>('cancelBell', {'id': _bellBaseId + i});
      } catch (_) {
        // Swallow — AlarmManager replaces stale alarms via FLAG_UPDATE_CURRENT anyway.
      }
    }
    // Also cancel the test bell (id=998) to avoid stale alarms.
    try {
      await _bellChannel.invokeMethod<void>('cancelBell', {'id': 998});
    } catch (_) {}
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
