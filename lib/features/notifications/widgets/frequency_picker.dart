import 'package:flutter/material.dart';

class FrequencyPicker extends StatelessWidget {
  const FrequencyPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton.outlined(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
          style: IconButton.styleFrom(
            side: BorderSide(color: scheme.outline),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            value == 1 ? 'bell per day' : 'bells per day',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withAlpha(160),
                ),
          ),
        ),
        const Spacer(),
        IconButton.outlined(
          onPressed: value < 10 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            side: BorderSide(color: scheme.outline),
          ),
        ),
      ],
    );
  }
}
