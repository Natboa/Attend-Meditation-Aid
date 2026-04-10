import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _timerSoundKey = 'timer_sound_id';
  static const _lastDurationKey = 'last_timer_duration_seconds';
  static const _hasSeenOnboardingKey = 'has_seen_onboarding';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  // Timer sound (independent of notification bell sound)
  String get timerSoundId => _prefs.getString(_timerSoundKey) ?? 'tibetan_bowl';
  Future<void> setTimerSoundId(String id) => _prefs.setString(_timerSoundKey, id);

  // Last used timer duration, for quick-start
  int? get lastDurationSeconds => _prefs.getInt(_lastDurationKey);
  Future<void> setLastDurationSeconds(int seconds) =>
      _prefs.setInt(_lastDurationKey, seconds);

  // Onboarding
  bool get hasSeenOnboarding => _prefs.getBool(_hasSeenOnboardingKey) ?? false;
  Future<void> markOnboardingSeen() =>
      _prefs.setBool(_hasSeenOnboardingKey, true);
}
