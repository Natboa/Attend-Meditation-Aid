import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.activeDays,
    required this.onChanged,
  });

  /// ISO weekday: 1 = Mon, 7 = Sun.
  final List<int> activeDays;
  final ValueChanged<List<int>> onChanged;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1;
        final active = activeDays.contains(day);
        return GestureDetector(
          onTap: () {
            final updated = List<int>.from(activeDays);
            if (active) {
              updated.remove(day);
            } else {
              updated.add(day);
              updated.sort();
            }
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active ? scheme.primary : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _labels[i],
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: active ? scheme.onPrimary : scheme.onSurface,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
