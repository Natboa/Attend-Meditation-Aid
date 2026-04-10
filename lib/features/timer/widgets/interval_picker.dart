import 'package:flutter/material.dart';

class IntervalPicker extends StatelessWidget {
  const IntervalPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Duration? selected;
  final ValueChanged<Duration?> onChanged;

  static const _options = <Duration?>[
    null,
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
  ];

  String _label(Duration? d) {
    if (d == null) return 'Off';
    return '${d.inMinutes}m';
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
            'Interval bells',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withAlpha(150),
                ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in _options) ...[
              _IntervalChip(
                label: _label(d),
                selected: selected == d,
                onTap: () => onChanged(d),
                scheme: scheme,
              ),
              if (d != _options.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _IntervalChip extends StatelessWidget {
  const _IntervalChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.secondary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? scheme.onSecondary : scheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
