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
    with SingleTickerProviderStateMixin {
  Duration? _selectedDuration = const Duration(minutes: 15);
  Duration? _selectedInterval;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _displayTime(TimerState s) {
    if (s.isIdle || s.target == null) {
      return DurationFormatter.format(
        _selectedDuration ?? const Duration(minutes: 15),
      );
    }
    if (s.target != null) {
      return DurationFormatter.format(s.remaining);
    }
    return DurationFormatter.format(s.elapsed);
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    // Listen for completion
    ref.listen(timerProvider, (prev, next) {
      if (next.isFinished && !(prev?.isFinished ?? false)) {
        _showFinishedDialog();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildDial(context, timer),
              const SizedBox(height: 40),
              if (timer.isIdle) ...[
                DurationPicker(
                  selected: _selectedDuration,
                  onChanged: (d) => setState(() => _selectedDuration = d),
                ),
                const SizedBox(height: 24),
                IntervalPicker(
                  selected: _selectedInterval,
                  onChanged: (d) => setState(() => _selectedInterval = d),
                ),
                const SizedBox(height: 40),
                _buildStartButton(context, notifier, scheme),
              ],
              if (timer.isRunning || timer.isPaused)
                _buildActiveControls(context, timer, notifier, scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDial(BuildContext context, TimerState timer) {
    final scheme = Theme.of(context).colorScheme;
    final isRunning = timer.isRunning;

    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = isRunning ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: TimerDial(
          progress: timer.progress,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayTime(timer),
                style: AppTextStyles.timerDisplay(context).copyWith(
                  color: scheme.onSurface,
                ),
              ),
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

  Widget _buildStartButton(
    BuildContext context,
    TimerNotifier notifier,
    ColorScheme scheme,
  ) {
    return FilledButton.icon(
      onPressed: () {
        HapticFeedback.mediumImpact();
        notifier.start(
          target: _selectedDuration,
          interval: _selectedInterval,
          soundId: _timerSoundId(ref),
        );
      },
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text(
        _selectedDuration == null
            ? 'Begin (open)'
            : 'Begin ${DurationFormatter.label(_selectedDuration!)}',
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size(200, 52),
        textStyle: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  String _timerSoundId(WidgetRef ref) =>
      ref.read(settingsRepositoryProvider).timerSoundId;

  Widget _buildActiveControls(
    BuildContext context,
    TimerState timer,
    TimerNotifier notifier,
    ColorScheme scheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop
        IconButton.outlined(
          onPressed: () async {
            HapticFeedback.lightImpact();
            await notifier.stop();
          },
          icon: const Icon(Icons.stop_rounded),
          iconSize: 28,
          style: IconButton.styleFrom(
            minimumSize: const Size(56, 56),
            side: BorderSide(color: scheme.outline),
          ),
        ),
        const SizedBox(width: 24),
        // Pause / Resume
        FilledButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            if (timer.isRunning) {
              notifier.pause();
            } else {
              notifier.resume();
            }
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size(72, 56),
          ),
          child: Icon(
            timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 28,
          ),
        ),
      ],
    );
  }

  void _showFinishedDialog() {
    final notifier = ref.read(timerProvider.notifier);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session complete'),
        content: const Text('Well done. Your session has been saved.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              notifier.dismissFinished();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
