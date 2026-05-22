import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/session_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/gatha_repository.dart';
import '../repositories/meditation_timer_repository.dart';

/// Overridden in main.dart with the real SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not initialized'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(),
);

final gathaRepositoryProvider = Provider<GathaRepository>(
  (ref) => GathaRepository(ref.watch(sharedPreferencesProvider)),
);

final meditationTimerRepositoryProvider = Provider<MeditationTimerRepository>(
  (ref) => MeditationTimerRepository(ref.watch(sharedPreferencesProvider)),
);
