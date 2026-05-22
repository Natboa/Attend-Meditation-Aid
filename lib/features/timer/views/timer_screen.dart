import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/meditation_timer.dart';
import '../../../core/utils/duration_formatter.dart';
import '../providers/meditation_timers_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/timer_state.dart';
import '../widgets/meditation_timer_picker.dart';
import '../widgets/timer_dial.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with TickerProviderStateMixin {
  // Captured when session finishes, shown on completion overlay
  Duration _completedElapsed = Duration.zero;
  bool _showCompletion = false;

  // Slow breathe-pulse while running
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Completion overlay: overlay fade + card scale + check pop
  late AnimationController _completionController;
  late Animation<double> _overlayFade;
  late Animation<double> _cardScale;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _overlayFade = CurvedAnimation(
      parent: _completionController,
      curve: Curves.easeOut,
    );

    _cardScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.easeOutBack),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _completionController,
        curve: const Interval(0.35, 1.0, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  String _displayTime(TimerState s, MeditationTimer? selectedTimer) {
    if (s.isIdle) {
      if (selectedTimer?.duration != null) {
        return DurationFormatter.format(selectedTimer!.duration!);
      }
      return '00:00';
    }
    if (s.target == null) {
      return DurationFormatter.format(s.elapsed);
    }
    return DurationFormatter.format(s.remaining);
  }

  Future<void> _dismissCompletion() async {
    await _completionController.reverse();
    setState(() => _showCompletion = false);
    ref.read(timerProvider.notifier).dismissFinished();
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final timers = ref.watch(meditationTimersProvider);
    final selectedTimer = ref.watch(selectedTimerProvider);

    ref.listen(timerProvider, (prev, next) {
      if (next.isFinished && !(prev?.isFinished ?? false)) {
        HapticFeedback.heavyImpact();
        _completedElapsed = next.elapsed;
        setState(() => _showCompletion = true);
        _completionController.forward(from: 0);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
        actions: [
          if (!timer.isActive) ...[
            IconButton(
              icon: const Icon(Icons.history_outlined),
              tooltip: 'Session history',
              onPressed: () => context.pushNamed('session-history'),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'More options',
              onSelected: (val) {
                if (val == 'manage') {
                  context.pushNamed('manage-timers');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'manage',
                  child: Text('Manage Presets'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 5,
                    child: Center(child: _buildDial(context, timer, selectedTimer)),
                  ),
                  const SizedBox(height: 16),
                  // Animated switch between idle pickers and active controls
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: timer.isIdle
                        ? _IdleControls(
                            key: const ValueKey('idle'),
                            timers: timers,
                            selectedTimer: selectedTimer,
                            onTimerSelected: (t) {
                              ref.read(selectedTimerProvider.notifier).select(t);
                            },
                            onStart: () {
                              HapticFeedback.mediumImpact();
                              notifier.start(
                                target: selectedTimer?.duration,
                                interval: selectedTimer?.interval,
                                soundId: selectedTimer?.soundId ?? 'tibetan_bowl',
                              );
                            },
                          )
                        : timer.isActive
                            ? _ActiveControls(
                                key: const ValueKey('active'),
                                timer: timer,
                                onStop: () async {
                                  HapticFeedback.lightImpact();
                                  await notifier.stop();
                                },
                                onTogglePause: () {
                                  HapticFeedback.lightImpact();
                                  if (timer.isRunning) {
                                    notifier.pause();
                                  } else {
                                    notifier.resume();
                                  }
                                },
                              )
                            : const SizedBox.shrink(key: ValueKey('finished')),
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
                ],
              ),
            ),
          ),
          // Completion overlay
          if (_showCompletion)
            _CompletionOverlay(
              overlayFade: _overlayFade,
              cardScale: _cardScale,
              checkScale: _checkScale,
              elapsed: _completedElapsed,
              onDone: _dismissCompletion,
            ),
        ],
      ),
    );
  }

  Widget _buildDial(BuildContext context, TimerState timer, MeditationTimer? selectedTimer) {
    final scheme = Theme.of(context).colorScheme;
    final isRunning = timer.isRunning;

    final ringColor = timer.isPaused
        ? Color.lerp(scheme.primary, scheme.secondary, 0.6)!
        : scheme.primary;

    final timeWidget = Text(
      _displayTime(timer, selectedTimer),
      style: AppTextStyles.timerDisplay(context)
          .copyWith(color: scheme.onSurface),
    );

    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = isRunning ? _pulseAnimation.value : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: ringColor),
          duration: const Duration(milliseconds: 400),
          builder: (context, color, child) => TimerDial(
            progress: timer.progress,
            progressColor: color ?? scheme.primary,
            child: child!,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              timeWidget,
              if (timer.isActive && timer.interval != null)
                Text(
                  'every ${DurationFormatter.label(timer.interval!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(120),
                      ),
                ),
              if (timer.isPaused)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'paused',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface.withAlpha(120),
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Idle state: custom presets picker + start button ─────────────────

class _IdleControls extends StatelessWidget {
  const _IdleControls({
    super.key,
    required this.timers,
    required this.selectedTimer,
    required this.onTimerSelected,
    required this.onStart,
  });

  final List<MeditationTimer> timers;
  final MeditationTimer? selectedTimer;
  final ValueChanged<MeditationTimer> onTimerSelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    String startLabel;
    final duration = selectedTimer?.duration;
    if (duration != null) {
      startLabel = 'Begin ${DurationFormatter.label(duration)}';
    } else {
      startLabel = 'Begin Session';
    }

    return Column(
      children: [
        MeditationTimerPicker(
          timers: timers,
          selected: selectedTimer,
          onChanged: onTimerSelected,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(startLabel),
          style: FilledButton.styleFrom(
            minimumSize: const Size(200, 52),
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

// ── Active state: stop + pause/resume ──────────────────────────────────────

class _ActiveControls extends StatelessWidget {
  const _ActiveControls({
    super.key,
    required this.timer,
    required this.onStop,
    required this.onTogglePause,
  });

  final TimerState timer;
  final VoidCallback onStop;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.outlined(
          onPressed: onStop,
          icon: const Icon(Icons.stop_rounded),
          iconSize: 28,
          style: IconButton.styleFrom(
            minimumSize: const Size(56, 56),
            side: BorderSide(color: scheme.outline),
          ),
        ),
        const SizedBox(width: 24),
        FilledButton(
          onPressed: onTogglePause,
          style: FilledButton.styleFrom(minimumSize: const Size(72, 56)),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 28,
              key: ValueKey(timer.isRunning),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Session completion overlay ──────────────────────────────────────────────

class _CompletionOverlay extends StatelessWidget {
  const _CompletionOverlay({
    required this.overlayFade,
    required this.cardScale,
    required this.checkScale,
    required this.elapsed,
    required this.onDone,
  });

  final Animation<double> overlayFade;
  final Animation<double> cardScale;
  final Animation<double> checkScale;
  final Duration elapsed;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: overlayFade,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: ScaleTransition(
            scale: cardScale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: checkScale,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: scheme.primary.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 44,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Session complete',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w400,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DurationFormatter.format(elapsed),
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Well done.',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withAlpha(150),
                                ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: onDone,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(160, 48),
                        ),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
