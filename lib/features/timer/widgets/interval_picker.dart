import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IntervalPicker extends StatelessWidget {
  const IntervalPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.intervals,
    required this.onAdd,
    required this.onRemove,
  });

  final Duration? selected;
  final ValueChanged<Duration?> onChanged;

  /// All removable interval options managed by the parent (excludes "Off").
  final List<Duration> intervals;

  /// Called when the user taps "+". Parent shows dialog and appends to [intervals].
  final VoidCallback onAdd;

  /// Called when the user taps × on a chip. Parent removes it from [intervals].
  final ValueChanged<Duration> onRemove;

  String _label(Duration d) => '${d.inMinutes}m';

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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _IntervalChip(
              label: 'Off',
              selected: selected == null,
              onTap: () => onChanged(null),
              scheme: scheme,
            ),
            for (final d in intervals)
              _IntervalChip(
                label: _label(d),
                selected: selected == d,
                onTap: () => onChanged(d),
                onRemove: () => onRemove(d),
                scheme: scheme,
              ),
            _IntervalChip(
              label: '+',
              selected: false,
              onTap: onAdd,
              scheme: scheme,
            ),
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
    this.onRemove,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.fromLTRB(14, 8, onRemove != null ? 8 : 14, 8),
        decoration: BoxDecoration(
          color: selected ? scheme.secondary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? scheme.onSecondary : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: selected
                      ? scheme.onSecondary.withAlpha(180)
                      : scheme.onSurface.withAlpha(120),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

Future<Duration?> showCustomIntervalDialog(BuildContext context) {
  return showDialog<Duration>(
    context: context,
    builder: (_) => const _CustomIntervalDialog(),
  );
}

class _CustomIntervalDialog extends StatefulWidget {
  const _CustomIntervalDialog();

  @override
  State<_CustomIntervalDialog> createState() => _CustomIntervalDialogState();
}

class _CustomIntervalDialogState extends State<_CustomIntervalDialog> {
  final _controller = TextEditingController();
  int? _minutes;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final m = _minutes;
    if (m != null && m > 0) {
      Navigator.of(context).pop(Duration(minutes: m));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Custom interval'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: 'Minutes',
          suffixText: 'min',
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => setState(() => _minutes = int.tryParse(v)),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _minutes != null && _minutes! > 0 ? _submit : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
