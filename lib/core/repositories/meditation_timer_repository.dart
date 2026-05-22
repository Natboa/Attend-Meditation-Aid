import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meditation_timer.dart';

class MeditationTimerRepository {
  static const _key = 'meditation_timers';
  final SharedPreferences _prefs;

  MeditationTimerRepository(this._prefs);

  List<MeditationTimer> load() {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) {
      return _defaultTimers();
    }
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((e) => MeditationTimer.fromJson(e as Map<String, dynamic>))
          .where((t) => t.duration != null)
          .toList();
    } catch (_) {
      return _defaultTimers();
    }
  }

  Future<void> saveAll(List<MeditationTimer> timers) async {
    final jsonString = jsonEncode(timers.map((t) => t.toJson()).toList());
    await _prefs.setString(_key, jsonString);
  }

  List<MeditationTimer> _defaultTimers() {
    return [
      const MeditationTimer(
        id: 'default_5m',
        duration: Duration(minutes: 5),
        interval: null,
        soundId: 'tibetan_bowl',
      ),
      const MeditationTimer(
        id: 'default_10m',
        duration: Duration(minutes: 10),
        interval: null,
        soundId: 'tibetan_bowl',
      ),
      const MeditationTimer(
        id: 'default_15m',
        duration: Duration(minutes: 15),
        interval: Duration(minutes: 5),
        soundId: 'tibetan_bowl',
      ),
      const MeditationTimer(
        id: 'default_20m',
        duration: Duration(minutes: 20),
        interval: Duration(minutes: 5),
        soundId: 'tibetan_bowl',
      ),
    ];
  }
}
