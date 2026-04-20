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

/// Called by WorkManager in an isolate. Only used to refresh daily gatha content.
/// Bell scheduling is handled natively by BellSchedulerReceiver (no Flutter needed).
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
    if (config.dailyGathaEnabled) {
      await SchedulerService.instance.scheduleDailyGatha(config);
    }

    // Re-enqueue for tomorrow.
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

Future<void> initWorkManager() async {
  await Workmanager().initialize(backgroundTaskDispatcher);
}

Future<void> _enqueueDailyTask({Duration delay = Duration.zero}) async {
  await Workmanager().registerOneOffTask(
    _dailyTaskName,
    _dailyTaskName,
    tag: _dailyTaskTag,
    initialDelay: delay,
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}

Future<void> triggerDailyScheduler() => _enqueueDailyTask();

Future<void> cancelDailyScheduler() =>
    Workmanager().cancelByTag(_dailyTaskTag);
