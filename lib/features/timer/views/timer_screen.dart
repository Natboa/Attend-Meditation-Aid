import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/repositories.dart';
import '../../../core/utils/duration_formatter.dart';
import '../providers/timer_provider.dart';
import '../providers/timer_state.dart';
import '../widgets/timer_dial.dart';
import '../widgets/duration_picker.dart';
import '../widgets/interval_picker.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with TickerProviderStateMixin {
  // Default to 5 min; user can pick 5, 10, custom, or ∞
  Duration? _selectedDuration = const Duration(minutes: 5);
  Duration? _selectedInterval;
  // Single user-added custom duration (replaces any previous custom)
  Duration? _customDuration;

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

  String _displayTime(TimerState s) {
    if (s.isIdle || s.target == null) {
      return DurationFormatter.format(
        _selectedDuration ?? const Duration(minutes: 5),
      );
    }
    return DurationFormatter.format(s.remaining);
  }

  String _timerSoundId() => ref.read(settingsRepositoryProvider).timerSoundId;

  Future<void> _openCustomDurationDialog() async {
    final result = await showCustomDurationDialog(context);
    if (result != null) {
      setState(() {
        _customDuration = result;
        _selectedDuration = result;
      });
    }
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
          if (!timer.isActive)
            IconButton(
              icon: const Icon(Icons.history_outlined),
              tooltip: 'Session history',
              onPressed: () => context.pushNamed('session-history'),
            ),
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
                    child: Center(child: _buildDial(context, timer)),
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
                            selectedDuration: _selectedDuration,
                            selectedInterval: _selectedInterval,
                            customDuration: _customDuration,
                            onDurationChanged: (d) =>
                                setState(() => _selectedDuration = d),
                            onIntervalChanged: (d) =>
                                setState(() => _selectedInterval = d),
                            onAddCustom: _openCustomDurationDialog,
                            onStart: () {
                              HapticFeedback.mediumImpact();
                              notifier.start(
                                target: _selectedDuration,
                                interval: _selectedInterval,
                                soundId: _timerSoundId(),
                              );
                            },
                            selectedDurationLabel: _selectedDuration != null
                                ? DurationFormatter.label(_selectedDuration!)
                                : null,
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

  Widget _buildDial(BuildContext context, TimerState timer) {
    final scheme = Theme.of(context).colorScheme;
    final isRunning = timer.isRunning;

    final ringColor = timer.isPaused
        ? Color.lerp(scheme.primary, scheme.secondary, 0.6)!
        : scheme.primary;

    // When idle, tapping the time display opens the custom duration dialog
    final timeWidget = timer.isIdle
        ? GestureDetector(
            onTap: _openCustomDurationDialog,
            child: Text(
              _displayTime(timer),
              style: AppTextStyles.timerDisplay(context)
                  .copyWith(color: scheme.onSurface),
            ),
          )
        : Text(
            _displayTime(timer),
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

// ── Idle state: duration + interval pickers + start button ─────────────────

class _IdleControls extends StatelessWidget {
  const _IdleControls({
    super.key,
    required this.selectedDuration,
    required this.selectedInterval,
    required this.customDuration,
    required this.onDurationChanged,
    required this.onIntervalChanged,
    required this.onAddCustom,
    required this.onStart,
    required this.selectedDurationLabel,
  });

  final Duration? selectedDuration;
  final Duration? selectedInterval;
  final Duration? customDuration;
  final ValueChanged<Duration?> onDurationChanged;
  final ValueChanged<Duration?> onIntervalChanged;
  final VoidCallback onAddCustom;
  final VoidCallback onStart;
  final String? selectedDurationLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DurationPicker(
          selected: selectedDuration,
          onChanged: onDurationChanged,
          customDuration: customDuration,
          onAddCustom: onAddCustom,
        ),
        const SizedBox(height: 20),
        IntervalPicker(
          selected: selectedInterval,
          onChanged: onIntervalChanged,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
            selectedDurationLabel != null
                ? 'Begin $selectedDurationLabel'
                : 'Begin (open)',
          ),
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
