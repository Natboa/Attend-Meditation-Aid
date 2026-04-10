import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/sound_option.dart';
import '../../../core/providers/repositories.dart';
import '../../../core/services/audio_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late String _timerSoundId;

  @override
  void initState() {
    super.initState();
    _timerSoundId = ref.read(settingsRepositoryProvider).timerSoundId;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.read(settingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: scheme.primary),
            title: const Text('Mindfulness bells'),
            subtitle: const Text('Random reminders throughout the day'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('notification-settings'),
          ),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Timer sound',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withAlpha(140),
                    letterSpacing: 0.4,
                  ),
            ),
          ),
          ...SoundOption.all.map((sound) {
            final selected = _timerSoundId == sound.id;
            return ListTile(
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
                onPressed: () => AudioService.instance.previewSound(sound.id),
              ),
              onTap: () {
                setState(() => _timerSoundId = sound.id);
                settings.setTimerSoundId(sound.id);
              },
            );
          }),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.info_outline,
                color: scheme.onSurface.withAlpha(120)),
            title: const Text('Attend'),
            subtitle: const Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }
}
