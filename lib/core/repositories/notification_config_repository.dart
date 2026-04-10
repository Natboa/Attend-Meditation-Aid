import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_config.dart';

/// Persists [NotificationConfig] as JSON in SharedPreferences so it is
/// accessible from both the main isolate and the WorkManager isolate.
class NotificationConfigRepository {
  static const _key = 'notification_config';

  final SharedPreferences _prefs;

  NotificationConfigRepository(this._prefs);

  NotificationConfig load() {
    final json = _prefs.getString(_key);
    if (json == null) return NotificationConfig.defaults();
    try {
      return _fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return NotificationConfig.defaults();
    }
  }

  Future<void> save(NotificationConfig config) async {
    await _prefs.setString(_key, jsonEncode(_toJson(config)));
  }

  Map<String, dynamic> _toJson(NotificationConfig c) => {
        'enabled': c.enabled,
        'activeDays': c.activeDays,
        'startHour': c.startHour,
        'endHour': c.endHour,
        'frequencyPerDay': c.frequencyPerDay,
        'bellSoundId': c.bellSoundId,
        'dailyGathaEnabled': c.dailyGathaEnabled,
        'dailyGathaHour': c.dailyGathaHour,
      };

  NotificationConfig _fromJson(Map<String, dynamic> j) => NotificationConfig(
        enabled: j['enabled'] as bool,
        activeDays: (j['activeDays'] as List).cast<int>(),
        startHour: j['startHour'] as int,
        endHour: j['endHour'] as int,
        frequencyPerDay: j['frequencyPerDay'] as int,
        bellSoundId: j['bellSoundId'] as String,
        dailyGathaEnabled: j['dailyGathaEnabled'] as bool,
        dailyGathaHour: j['dailyGathaHour'] as int,
      );
}
