import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/meditation_timer.dart';
import '../../../core/models/sound_option.dart';
import '../providers/meditation_timers_provider.dart';
import '../widgets/timer_form_dialog.dart';

class ManageTimersScreen extends ConsumerWidget {
  const ManageTimersScreen({super.key});

  Future<void> _openTimerForm(BuildContext context, WidgetRef ref, [MeditationTimer? timer]) async {
    final result = await showDialog<MeditationTimer>(
      context: context,
      builder: (_) => TimerFormDialog(timer: timer),
    );
    if (result != null) {
      if (timer == null) {
        final newTimer = result.copyWith(id: const Uuid().v4());
        await ref.read(meditationTimersProvider.notifier).addTimer(newTimer);
      } else {
        final updatedTimer = result.copyWith(id: timer.id);
        await ref.read(meditationTimersProvider.notifier).updateTimer(updatedTimer);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, MeditationTimer timer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Preset'),
        content: const Text('Are you sure you want to delete this meditation preset?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(meditationTimersProvider.notifier).deleteTimer(timer.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timers = ref.watch(meditationTimersProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create preset',
            onPressed: () => _openTimerForm(context, ref),
          ),
        ],
      ),
      body: timers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 64,
                    color: scheme.onSurface.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No presets available',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface.withAlpha(150),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a preset to start meditating.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withAlpha(100),
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _openTimerForm(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Preset'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: timers.length,
              itemBuilder: (context, index) {
                final timer = timers[index];
                final sound = SoundOption.findById(timer.soundId);

                final durLabel = timer.duration != null ? '${timer.duration!.inMinutes} minutes' : '';
                final intLabel = timer.interval != null ? 'Interval bell: every ${timer.interval!.inMinutes}m' : 'No interval bells';
                final soundLabel = 'Sound: ${sound.displayName}';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: scheme.primary,
                      ),
                    ),
                    title: Text(
                      durLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            intLabel,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withAlpha(160),
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            soundLabel,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withAlpha(120),
                                ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit preset',
                          onPressed: () => _openTimerForm(context, ref, timer),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          tooltip: 'Delete preset',
                          color: scheme.error,
                          onPressed: () => _confirmDelete(context, ref, timer),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: timers.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _openTimerForm(context, ref),
              tooltip: 'Create preset',
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}
