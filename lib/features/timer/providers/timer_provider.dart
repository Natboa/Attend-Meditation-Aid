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
  int _sessionToken = 0;

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

    final token = ++_sessionToken;
    final now = DateTime.now();

    final settings = ref.read(settingsRepositoryProvider);

    state = TimerState(
      status: TimerStatus.running,
      elapsed: Duration.zero,
      target: target,
      interval: interval,
      soundId: soundId,
      startedAt: now,
      lastIntervalAt: Duration.zero,
    );

    // Register notification action callbacks
    _registerNotificationCallbacks();

    // Start ticking immediately; platform side-effects should not delay the countdown.
    _ticker = Timer.periodic(_tickInterval, _onTick);

    if (target != null) {
      unawaited(settings.setLastDurationSeconds(target.inSeconds));
    }

    unawaited(() async {
      await WakelockPlus.enable();
    }());

    // Show the timer notification (guard against stop/restart races).
    unawaited(() async {
      if (token != _sessionToken) return;
      await NotificationService.instance.showTimerNotification(
        remaining: target ?? const Duration(hours: 9),
      );
    }());

    // Play the opening bell in the background (guard against stop/restart races).
    unawaited(() async {
      if (token != _sessionToken) return;
      await AudioService.instance.playBell(soundId);
    }());
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

    final startedAt = s.startedAt;
    if (startedAt == null) return;

    final newElapsed = DateTime.now().difference(startedAt);

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

    // Since we're pushing manual text updates instead of using the OS chronometer,
    // update the notification every second (but not faster) to avoid spamming the system.
    final prevElapsedSec = s.elapsed.inSeconds;
    final newElapsedSec = newElapsed.inSeconds;
    if (newElapsedSec > prevElapsedSec) {
      final remaining = s.target != null ? s.target! - newElapsed : const Duration(hours: 9);
      unawaited(NotificationService.instance.showTimerNotification(remaining: remaining));
    }

    state = s.copyWith(
      elapsed: newElapsed,
      lastIntervalAt: newLastInterval,
    );
  }

  void pause() {
    if (!state.isRunning) return;
    final startedAt = state.startedAt;
    final elapsedNow = startedAt != null
        ? DateTime.now().difference(startedAt)
        : state.elapsed;
    _ticker?.cancel();
    state = state.copyWith(status: TimerStatus.paused, elapsed: elapsedNow);
    final remaining = state.target != null
        ? state.target! - state.elapsed
        : const Duration(hours: 9);
    NotificationService.instance.pauseTimerNotification(remaining);
  }

  void resume() {
    if (!state.isPaused) return;
    // Re-anchor startedAt so that DateTime.now() - startedAt == current elapsed.
    final newStartedAt = DateTime.now().subtract(state.elapsed);
    _ticker = Timer.periodic(_tickInterval, _onTick);
    state = state.copyWith(status: TimerStatus.running, startedAt: newStartedAt);
    final remaining = state.target != null
        ? state.target! - state.elapsed
        : const Duration(hours: 9);
    NotificationService.instance.resumeTimerNotification(remaining);
  }

  Future<void> stop() async {
    if (!state.isActive) return;

    _sessionToken++;
    _ticker?.cancel();
    TimerNotificationController.instance.clear();

    // Capture everything needed for session save before resetting state.
    final startedAt = state.startedAt;
    final elapsedNow = (state.isRunning && startedAt != null)
        ? DateTime.now().difference(startedAt)
        : state.elapsed;
    final soundId = state.soundId;
    final target = state.target;
    final interval = state.interval;

    // Reset UI immediately so the user isn't stuck looking at the running timer
    // while async cleanup (save, wakelock, notification cancel) finishes.
    state = const TimerState();

    unawaited(NotificationService.instance.cancelTimerNotification());
    unawaited(WakelockPlus.disable());
    if (elapsedNow.inSeconds >= 5) {
      unawaited(() async {
        final session = TimerSession(
          id: const Uuid().v4(),
          startedAt: startedAt ?? DateTime.now(),
          durationSeconds: elapsedNow.inSeconds,
          targetSeconds: target?.inSeconds,
          completed: false,
          soundId: soundId,
          intervalSeconds: interval?.inSeconds,
        );
        await ref.read(sessionRepositoryProvider).save(session);
      }());
    }
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
