import 'package:flutter/material.dart';

class DurationPicker extends StatelessWidget {
  const DurationPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Duration? selected;
  final ValueChanged<Duration?> onChanged;

  static const _presets = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 20),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
  ];

  String _label(Duration d) {
    final m = d.inMinutes;
    if (m < 60) return '${m}m';
    return '${d.inHours}h';
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
            'Duration',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withAlpha(150),
                ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _presets) _Chip(
              label: _label(d),
              selected: selected == d,
              onTap: () => onChanged(d),
              scheme: scheme,
            ),
            _Chip(
              label: '∞',
              selected: selected == null,
              onTap: () => onChanged(null),
              scheme: scheme,
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
