import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/models/sound_option.dart';
import '../../../core/models/timer_session.dart';
import '../../../core/providers/repositories.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/timer_notification_controller.dart';
import 'timer_state.dart';

class TimerNotifier extends Notifier<TimerState> {
  static const _tickInterval = Duration(milliseconds: 100);

  Timer? _ticker;

  @override
  TimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const TimerState();
  }

  Future<void> start({
    required Duration? target,
    required Duration? interval,
    required String soundId,
  }) async {
    _ticker?.cancel();

    final settings = ref.read(settingsRepositoryProvider);

    state = TimerState(
      status: TimerStatus.running,
      elapsed: Duration.zero,
      target: target,
      interval: interval,
      soundId: soundId,
      startedAt: DateTime.now(),
      lastIntervalAt: Duration.zero,
    );

    if (target != null) {
      await settings.setLastDurationSeconds(target.inSeconds);
    }

    await WakelockPlus.enable();
    // Play the opening bell and wait for it to finish before the countdown starts
    await AudioService.instance.playBellAndAwait(soundId);

    // Update startedAt to after the bell, so elapsed time is accurate
    state = state.copyWith(startedAt: DateTime.now());

    // Register notification action callbacks
    _registerNotificationCallbacks();

    // Show the timer notification
    final soundName = SoundOption.findById(soundId).displayName;
    await NotificationService.instance.showTimerNotification(
      remaining: target ?? const Duration(hours: 9),
      soundName: soundName,
    );

    _ticker = Timer.periodic(_tickInterval, _onTick);
  }

  void _registerNotificationCallbacks() {
    final ctrl = TimerNotificationController.instance;
    ctrl.onPause = pause;
    ctrl.onResume = resume;
    ctrl.onStop = () => stop();
  }

  void _onTick(Timer _) {
    final s = state;
    if (!s.isRunning) return;

    final newElapsed = s.elapsed + _tickInterval;

    // Check interval bell
    Duration newLastInterval = s.lastIntervalAt;
    if (s.interval != null) {
      final intervalMs = s.interval!.inMilliseconds;
      final prevBeat = s.lastIntervalAt.inMilliseconds ~/ intervalMs;
      final newBeat = newElapsed.inMilliseconds ~/ intervalMs;
      if (newBeat > prevBeat && newElapsed > s.interval!) {
        newLastInterval = newElapsed;
        AudioService.instance.playBell(s.soundId);
      }
    }

    // Check if target reached
    if (s.target != null && newElapsed >= s.target!) {
      _finish(s.target!, completed: true);
      return;
    }

    state = s.copyWith(
      elapsed: newElapsed,
      lastIntervalAt: newLastInterval,
    );
  }

  void pause() {
    if (!state.isRunning) return;
    _ticker?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
    final remaining = state.target != null
        ? state.target! - state.elapsed
        : const Duration(hours: 9);
    NotificationService.instance.pauseTimerNotification(remaining);
  }

  void resume() {
    if (!state.isPaused) return;
    _ticker = Timer.periodic(_tickInterval, _onTick);
    state = state.copyWith(status: TimerStatus.running);
    final remaining = state.target != null
        ? state.target! - state.elapsed
        : const Duration(hours: 9);
    NotificationService.instance.resumeTimerNotification(remaining);
  }

  Future<void> stop() async {
    if (!state.isActive) return;
    _ticker?.cancel();
    await _saveSession(state.elapsed, completed: false);
    await WakelockPlus.disable();
    await NotificationService.instance.cancelTimerNotification();
    TimerNotificationController.instance.clear();
    state = const TimerState();
  }

  Future<void> _finish(Duration elapsed, {required bool completed}) async {
    _ticker?.cancel();
    state = state.copyWith(
      status: TimerStatus.finished,
      elapsed: elapsed,
    );
    await AudioService.instance.playBell(state.soundId);
    await _saveSession(elapsed, completed: completed);
    await WakelockPlus.disable();
    await NotificationService.instance.cancelTimerNotification();
    TimerNotificationController.instance.clear();
  }

  Future<void> _saveSession(Duration elapsed, {required bool completed}) async {
    if (elapsed.inSeconds < 5) return; // ignore micro-sessions
    final session = TimerSession(
      id: const Uuid().v4(),
      startedAt: state.startedAt ?? DateTime.now(),
      durationSeconds: elapsed.inSeconds,
      targetSeconds: state.target?.inSeconds,
      completed: completed,
      soundId: state.soundId,
      intervalSeconds: state.interval?.inSeconds,
    );
    await ref.read(sessionRepositoryProvider).save(session);
  }

  void dismissFinished() {
    if (state.isFinished) state = const TimerState();
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(
  TimerNotifier.new,
);
