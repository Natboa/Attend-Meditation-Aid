import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'app.dart';
import 'core/models/timer_session.dart';
import 'core/providers/repositories.dart';
import 'core/repositories/session_repository.dart';
import 'core/repositories/notification_config_repository.dart';
import 'core/services/audio_service.dart';
import 'core/services/background_scheduler.dart';
import 'core/services/notification_service.dart';
import 'core/services/scheduler_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TimerSessionAdapter());
  await SessionRepository.openBox();

  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Timezone (required by flutter_local_notifications zonedSchedule)
  tz.initializeTimeZones();

  // Audio
  await AudioService.instance.init();

  // Notifications
  await NotificationService.instance.init();

  // WorkManager
  await initWorkManager();

  // Self-heal: reschedule bells on every cold start so a missed WorkManager
  // firing (Samsung/Xiaomi kill aggressive OEMs) doesn't silence bells permanently.
  final config = NotificationConfigRepository(prefs).load();
  if (config.enabled) {
    await SchedulerService.instance.rescheduleBells(config);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AttendApp(),
    ),
  );
}
