import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DurationPicker extends StatelessWidget {
  const DurationPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.durations,
    required this.onAdd,
    required this.onRemove,
  });

  final Duration? selected;
  final ValueChanged<Duration?> onChanged;

  /// All removable duration chips managed by the parent.
  final List<Duration> durations;

  /// Called when the user taps "+". Parent shows dialog and appends to [durations].
  final VoidCallback onAdd;

  /// Called when the user taps × on a chip. Parent removes it from [durations].
  final ValueChanged<Duration> onRemove;

  String _label(Duration d) {
    final m = d.inMinutes;
    if (m < 60) return '${m}m';
    return '${d.inHours}h${d.inMinutes.remainder(60) > 0 ? ' ${d.inMinutes.remainder(60)}m' : ''}';
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
            for (final d in durations)
              _Chip(
                label: _label(d),
                selected: selected == d,
                onTap: () => onChanged(d),
                onRemove: () => onRemove(d),
                scheme: scheme,
              ),
            _Chip(
              label: '∞',
              selected: selected == null,
              onTap: () => onChanged(null),
              scheme: scheme,
            ),
            _Chip(
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

// ---------------------------------------------------------------------------

class _Chip extends StatelessWidget {
  const _Chip({
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
    final bg = selected ? scheme.primary : scheme.surfaceContainerHighest;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );

    // When removable: split into two visually-joined tap zones so the label
    // area (select) and the × area (delete) have no overlap.
    if (onRemove != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
              child: Text(label, style: labelStyle),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: selected
                      ? scheme.onPrimary.withAlpha(180)
                      : scheme.onSurface.withAlpha(120),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: labelStyle),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable dialog — call showCustomDurationDialog() from anywhere.

Future<Duration?> showCustomDurationDialog(BuildContext context) {
  return showDialog<Duration>(
    context: context,
    builder: (_) => const _CustomDurationDialog(),
  );
}

class _CustomDurationDialog extends StatefulWidget {
  const _CustomDurationDialog();

  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
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
      title: const Text('Custom duration'),
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
