enum TimerStatus { idle, running, paused, finished }

class TimerState {
  const TimerState({
    this.status = TimerStatus.idle,
    this.elapsed = Duration.zero,
    this.target,
    this.interval,
    this.soundId = 'tibetan_bowl',
    this.startedAt,
    this.lastIntervalAt = Duration.zero,
  });

  final TimerStatus status;
  final Duration elapsed;

  /// Null means open-ended session.
  final Duration? target;

  /// Null means no interval bells.
  final Duration? interval;

  final String soundId;
  final DateTime? startedAt;

  /// How far elapsed was when the last interval bell fired.
  final Duration lastIntervalAt;

  bool get isIdle => status == TimerStatus.idle;
  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isFinished => status == TimerStatus.finished;
  bool get isActive => isRunning || isPaused;

  double get progress {
    if (target == null || target!.inMilliseconds == 0) return 0;
    return (elapsed.inMilliseconds / target!.inMilliseconds).clamp(0.0, 1.0);
  }

  Duration get remaining {
    if (target == null) return Duration.zero;
    final r = target! - elapsed;
    return r.isNegative ? Duration.zero : r;
  }

  TimerState copyWith({
    TimerStatus? status,
    Duration? elapsed,
    Duration? target,
    Duration? interval,
    String? soundId,
    DateTime? startedAt,
    Duration? lastIntervalAt,
  }) {
    return TimerState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      target: target ?? this.target,
      interval: interval ?? this.interval,
      soundId: soundId ?? this.soundId,
      startedAt: startedAt ?? this.startedAt,
      lastIntervalAt: lastIntervalAt ?? this.lastIntervalAt,
    );
  }
}
