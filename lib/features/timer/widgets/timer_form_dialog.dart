import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/meditation_timer.dart';
import '../../../core/models/sound_option.dart';
import '../../../core/services/audio_service.dart';

class TimerFormDialog extends StatefulWidget {
  const TimerFormDialog({
    super.key,
    this.timer,
  });

  final MeditationTimer? timer;

  @override
  State<TimerFormDialog> createState() => _TimerFormDialogState();
}

class _TimerFormDialogState extends State<TimerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _durationController;
  late bool _enableIntervals;
  late final TextEditingController _intervalController;
  late String _selectedSoundId;

  String? _playingSoundId;
  Timer? _previewStateTimer;

  @override
  void initState() {
    super.initState();
    final t = widget.timer;

    _durationController = TextEditingController(
      text: t?.duration != null ? t!.duration!.inMinutes.toString() : '10',
    );
    _enableIntervals = t != null && t.interval != null;
    _intervalController = TextEditingController(
      text: t?.interval != null ? t!.interval!.inMinutes.toString() : '5',
    );
    _selectedSoundId = t?.soundId ?? 'tibetan_bowl';
  }

  @override
  void dispose() {
    _durationController.dispose();
    _intervalController.dispose();
    _previewStateTimer?.cancel();
    AudioService.instance.stop();
    super.dispose();
  }

  void _playPreview(String soundId) {
    _previewStateTimer?.cancel();
    if (_playingSoundId == soundId) {
      AudioService.instance.stop();
      setState(() {
        _playingSoundId = null;
      });
    } else {
      AudioService.instance.previewSound(soundId);
      setState(() {
        _playingSoundId = soundId;
      });
      _previewStateTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _playingSoundId = null;
          });
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final durationMin = int.tryParse(_durationController.text);
    final intervalMin = _enableIntervals ? int.tryParse(_intervalController.text) : null;

    final result = MeditationTimer(
      id: widget.timer?.id ?? '', // ID generated/assigned by parent if empty
      duration: durationMin != null ? Duration(minutes: durationMin) : null,
      interval: intervalMin != null ? Duration(minutes: intervalMin) : null,
      soundId: _selectedSoundId,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.timer != null ? 'Edit Preset' : 'Create Preset'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Duration Input
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Duration (Minutes)',
                  hintText: 'e.g. 15',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter a duration';
                  }
                  final num = int.tryParse(val);
                  if (num == null || num <= 0) {
                    return 'Must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interval Bells Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable interval bells'),
                subtitle: const Text('Play sound periodically during session'),
                value: _enableIntervals,
                onChanged: (val) {
                  setState(() {
                    _enableIntervals = val;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Interval Input (if enabled)
              if (_enableIntervals)
                TextFormField(
                  controller: _intervalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Interval (Minutes)',
                    hintText: 'e.g. 5',
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter interval';
                    }
                    final intervalNum = int.tryParse(val);
                    if (intervalNum == null || intervalNum <= 0) {
                      return 'Must be greater than 0';
                    }
                    final durNum = int.tryParse(_durationController.text) ?? 0;
                    if (durNum > 0 && intervalNum >= durNum) {
                      return 'Interval must be less than duration';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // Sound Dropdown with Preview Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedSoundId,
                      decoration: InputDecoration(
                        labelText: 'Timer Sound',
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: SoundOption.all.map((s) {
                        return DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSoundId = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: scheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _playingSoundId == _selectedSoundId
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: scheme.primary,
                        ),
                        onPressed: () => _playPreview(_selectedSoundId),
                        tooltip: 'Preview sound',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
