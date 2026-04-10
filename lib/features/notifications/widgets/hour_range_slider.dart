import 'package:flutter/material.dart';

class HourRangeSlider extends StatelessWidget {
  const HourRangeSlider({
    super.key,
    required this.startHour,
    required this.endHour,
    required this.onChanged,
  });

  final int startHour;
  final int endHour;
  final void Function(int start, int end) onChanged;

  String _fmt(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _fmt(startHour),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '→',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(100),
                  ),
            ),
            Text(
              _fmt(endHour),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        RangeSlider(
          min: 0,
          max: 23,
          divisions: 23,
          values: RangeValues(startHour.toDouble(), endHour.toDouble()),
          onChanged: (v) {
            final s = v.start.round();
            final e = v.end.round();
            if (e > s) onChanged(s, e);
          },
          activeColor: scheme.primary,
          inactiveColor: scheme.surfaceContainerHighest,
        ),
      ],
    );
  }
}
