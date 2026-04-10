import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/sound_option.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/permission_service.dart';
import '../providers/notification_config_provider.dart';
import '../widgets/day_selector.dart';
import '../widgets/frequency_picker.dart';
import '../widgets/hour_range_slider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(notificationConfigProvider);
    final notifier = ref.read(notificationConfigProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mindfulness bells')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Master toggle
          _Section(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enable',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Receive random bell reminders throughout the day',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withAlpha(130),
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: config.enabled,
                  onChanged: (v) async {
                    if (v) {
                      final granted = await PermissionService.instance
                          .requestNotificationPermission();
                      if (!granted) return;
                      final hasExact = await PermissionService.instance
                          .hasExactAlarmPermission();
                      if (!hasExact && context.mounted) {
                        await PermissionService.instance
                            .showExactAlarmDialog(context);
                      }
                      final batteryIgnored = await PermissionService.instance
                          .isBatteryOptimizationIgnored();
                      if (!batteryIgnored) {
                        await PermissionService.instance
                            .requestBatteryOptimizationExemption();
                      }
                    }
                    await notifier.setEnabled(v);
                  },
                ),
              ],
            ),
          ),

          if (config.enabled) ...[
            const SizedBox(height: 16),

            // Days
            _Section(
              label: 'Active days',
              child: DaySelector(
                activeDays: config.activeDays,
                onChanged: notifier.updateDays,
              ),
            ),
            const SizedBox(height: 16),

            // Time window
            _Section(
              label: 'Time window',
              child: HourRangeSlider(
                startHour: config.startHour,
                endHour: config.endHour,
                onChanged: notifier.updateHourRange,
              ),
            ),
            const SizedBox(height: 16),

            // Frequency
            _Section(
              label: 'How many',
              child: FrequencyPicker(
                value: config.frequencyPerDay,
                onChanged: notifier.updateFrequency,
              ),
            ),
            const SizedBox(height: 16),

            // Sound picker
            _Section(
              label: 'Bell sound',
              child: Column(
                children: SoundOption.all.map((sound) {
                  final selected = config.bellSoundId == sound.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? scheme.primary : scheme.onSurface.withAlpha(100),
                    ),
                    title: Text(sound.displayName),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_outline, size: 22),
                      tooltip: 'Preview',
                      onPressed: () =>
                          AudioService.instance.previewSound(sound.id),
                    ),
                    onTap: () => notifier.updateBellSound(sound.id),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Next scheduled preview
            _NextBellsPreview(config: config),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.label});

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withAlpha(140),
                    letterSpacing: 0.4,
                  ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _NextBellsPreview extends ConsumerWidget {
  const _NextBellsPreview({required this.config});

  final dynamic config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // Import SchedulerService to compute preview times
    return _NextBellsPreviewInner(scheme: scheme);
  }
}

class _NextBellsPreviewInner extends StatelessWidget {
  const _NextBellsPreviewInner({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bells will ring at random times in your configured window.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(160),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
