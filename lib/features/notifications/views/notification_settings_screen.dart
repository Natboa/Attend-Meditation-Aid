import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/notification_config.dart';
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
          // ── Mindfulness bells toggle ──────────────────────────────────────
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

            _Section(
              label: 'Active days',
              child: DaySelector(
                activeDays: config.activeDays,
                onChanged: notifier.updateDays,
              ),
            ),
            const SizedBox(height: 16),

            _Section(
              label: 'Time window',
              child: HourRangeSlider(
                startHour: config.startHour,
                endHour: config.endHour,
                onChanged: notifier.updateHourRange,
              ),
            ),
            const SizedBox(height: 16),

            _Section(
              label: 'How many',
              child: FrequencyPicker(
                value: config.frequencyPerDay,
                onChanged: notifier.updateFrequency,
              ),
            ),
            const SizedBox(height: 16),

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
                      color: selected
                          ? scheme.primary
                          : scheme.onSurface.withAlpha(100),
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

            _BellScheduleSummary(config: config),
          ],

          const SizedBox(height: 24),
          Divider(color: scheme.outline.withAlpha(60)),
          const SizedBox(height: 24),

          // ── Daily poem toggle ─────────────────────────────────────────────
          _Section(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily poem',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Receive the poem of the day each morning',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withAlpha(130),
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: config.dailyGathaEnabled,
                  onChanged: (v) async {
                    if (v) {
                      final granted = await PermissionService.instance
                          .requestNotificationPermission();
                      if (!granted) return;
                    }
                    await notifier.setDailyGathaEnabled(v);
                  },
                ),
              ],
            ),
          ),

          if (config.dailyGathaEnabled) ...[
            const SizedBox(height: 16),
            _Section(
              label: 'Delivery time',
              child: _HourChips(
                selected: config.dailyGathaHour,
                onChanged: notifier.setDailyGathaHour,
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Bell schedule summary ─────────────────────────────────────────────────────

class _BellScheduleSummary extends StatelessWidget {
  const _BellScheduleSummary({required this.config});

  final NotificationConfig config;

  static const _dayLabels = {
    1: 'Mon', 2: 'Tue', 3: 'Wed',
    4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun',
  };

  String _formatHour(int h) {
    if (h == 0) return '12:00 AM';
    if (h < 12) return '$h:00 AM';
    if (h == 12) return '12:00 PM';
    return '${h - 12}:00 PM';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = List<int>.from(config.activeDays)..sort();
    final daysStr = days.map((d) => _dayLabels[d] ?? '').join(' · ');
    final count = config.frequencyPerDay;
    final bellWord = count == 1 ? 'bell' : 'bells';
    final summary =
        '$count $bellWord between ${_formatHour(config.startHour)} '
        'and ${_formatHour(config.endHour)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(180),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (daysStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    daysStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withAlpha(120),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hour chip picker for daily gatha ─────────────────────────────────────────

class _HourChips extends StatelessWidget {
  const _HourChips({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  static const _hours = [6, 7, 8, 9, 10, 11];
  static const _labels = {
    6: '6 AM', 7: '7 AM', 8: '8 AM',
    9: '9 AM', 10: '10 AM', 11: '11 AM',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _hours.map((h) {
        final isSelected = selected == h;
        return ChoiceChip(
          label: Text(_labels[h] ?? '$h:00'),
          selected: isSelected,
          onSelected: (_) => onChanged(h),
          selectedColor: scheme.primary.withAlpha(30),
          side: BorderSide(
            color: isSelected
                ? scheme.primary
                : scheme.outline.withAlpha(80),
          ),
          labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? scheme.primary
                    : scheme.onSurface.withAlpha(160),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        );
      }).toList(),
    );
  }
}

// ── Shared section container ──────────────────────────────────────────────────

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
