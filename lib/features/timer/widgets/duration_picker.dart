import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DurationPicker extends StatelessWidget {
  const DurationPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.customDuration,
    required this.onAddCustom,
  });

  final Duration? selected;
  final ValueChanged<Duration?> onChanged;
  /// A single user-added custom duration (managed by the parent).
  final Duration? customDuration;
  /// Called when the user taps "+". Parent should show the dialog and update [customDuration].
  final VoidCallback onAddCustom;

  static const _defaults = [
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];

  String _label(Duration d) {
    final m = d.inMinutes;
    if (m < 60) return '${m}m';
    return '${d.inHours}h${d.inMinutes.remainder(60) > 0 ? ' ${d.inMinutes.remainder(60)}m' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final chips = <Duration?>[..._defaults];
    if (customDuration != null && !_defaults.contains(customDuration)) {
      chips.add(customDuration);
    }
    chips.add(null); // ∞

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
            for (final d in chips)
              _Chip(
                label: d != null ? _label(d) : '∞',
                selected: selected == d,
                onTap: () => onChanged(d),
                scheme: scheme,
              ),
            _Chip(
              label: '+',
              selected: false,
              onTap: onAddCustom,
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
