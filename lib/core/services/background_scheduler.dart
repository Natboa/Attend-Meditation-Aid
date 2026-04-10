import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';
import '../models/notification_config.dart';
import '../services/notification_service.dart';
import '../services/scheduler_service.dart';

const _dailyTaskName = 'attend_daily_bell_scheduler';
const _dailyTaskTag = 'attend_bells';

/// Called by WorkManager in an isolate on Android.
@pragma('vm:entry-point')
void backgroundTaskDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _dailyTaskName) return Future.value(true);

    WidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();

    await NotificationService.instance.init();

    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('notification_config');
    if (json == null) return Future.value(true);

    final config = _configFromJson(jsonDecode(json) as Map<String, dynamic>);
    if (config.enabled) {
      await SchedulerService.instance.rescheduleBells(config);
    }

    // Re-enqueue for tomorrow
    await _enqueueDailyTask(delay: const Duration(hours: 24));
    return Future.value(true);
  });
}

NotificationConfig _configFromJson(Map<String, dynamic> json) =>
    NotificationConfig(
      enabled: json['enabled'] as bool,
      activeDays: (json['activeDays'] as List).cast<int>(),
      startHour: json['startHour'] as int,
      endHour: json['endHour'] as int,
      frequencyPerDay: json['frequencyPerDay'] as int,
      bellSoundId: json['bellSoundId'] as String,
      dailyGathaEnabled: json['dailyGathaEnabled'] as bool,
      dailyGathaHour: json['dailyGathaHour'] as int,
    );

/// Initialises WorkManager. Call once from [main].
Future<void> initWorkManager() async {
  await Workmanager().initialize(
    backgroundTaskDispatcher,
    isInDebugMode: false,
  );
}

/// Enqueues the daily bell scheduler task, optionally with an initial [delay].
Future<void> _enqueueDailyTask({Duration delay = Duration.zero}) async {
  await Workmanager().registerOneOffTask(
    _dailyTaskName,
    _dailyTaskName,
    tag: _dailyTaskTag,
    initialDelay: delay,
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.not_required),
  );
}

/// Public entry point — call when the user changes notification config.
Future<void> triggerDailyScheduler() => _enqueueDailyTask();

/// Cancel all scheduled work.
Future<void> cancelDailyScheduler() =>
    Workmanager().cancelByTag(_dailyTaskTag);
