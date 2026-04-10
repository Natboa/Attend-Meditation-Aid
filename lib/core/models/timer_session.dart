import 'package:hive_flutter/hive_flutter.dart';

part 'timer_session.g.dart';

@HiveType(typeId: 0)
class TimerSession extends HiveObject {
  TimerSession({
    required this.id,
    required this.startedAt,
    required this.durationSeconds,
    this.targetSeconds,
    required this.completed,
    required this.soundId,
    this.intervalSeconds,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startedAt;

  /// Actual elapsed time in seconds.
  @HiveField(2)
  final int durationSeconds;

  /// Target duration in seconds; null means open-ended.
  @HiveField(3)
  final int? targetSeconds;

  @HiveField(4)
  final bool completed;

  @HiveField(5)
  final String soundId;

  /// Interval bell duration in seconds; null means no interval bells.
  @HiveField(6)
  final int? intervalSeconds;

  Duration get duration => Duration(seconds: durationSeconds);
  Duration? get target => targetSeconds != null ? Duration(seconds: targetSeconds!) : null;
  Duration? get interval => intervalSeconds != null ? Duration(seconds: intervalSeconds!) : null;
}
