import 'package:flutter/material.dart';
import '../../../core/models/meditation_timer.dart';

class MeditationTimerPicker extends StatelessWidget {
  const MeditationTimerPicker({
    super.key,
    required this.timers,
    required this.selected,
    required this.onChanged,
  });

  final List<MeditationTimer> timers;
  final MeditationTimer? selected;
  final ValueChanged<MeditationTimer> onChanged;

  String _formatTimerLabel(MeditationTimer timer) {
    final durStr = timer.duration != null ? '${timer.duration!.inMinutes}m' : '∞';
    if (timer.interval != null) {
      return '$durStr (${timer.interval!.inMinutes}m bell)';
    }
    return durStr;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Meditation Preset',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withAlpha(150),
                ),
          ),
        ),
        if (timers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No presets available. Tap the 3 dots in the top right to create one.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withAlpha(120),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final timer in timers)
                _TimerChip(
                  label: _formatTimerLabel(timer),
                  selected: selected?.id == timer.id,
                  onTap: () => onChanged(timer),
                  scheme: scheme,
                ),
            ],
          ),
      ],
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? scheme.primary : scheme.surfaceContainerHighest;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: labelStyle),
      ),
    );
  }
}
