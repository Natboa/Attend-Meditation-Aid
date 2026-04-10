import 'package:hive_flutter/hive_flutter.dart';
import '../models/timer_session.dart';

class SessionRepository {
  static const _boxName = 'timer_sessions';

  Box<TimerSession> get _box => Hive.box<TimerSession>(_boxName);

  static Future<void> openBox() async {
    await Hive.openBox<TimerSession>(_boxName);
  }

  Future<void> save(TimerSession session) async {
    await _box.put(session.id, session);
  }

  List<TimerSession> getAll() {
    final sessions = _box.values.toList();
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
