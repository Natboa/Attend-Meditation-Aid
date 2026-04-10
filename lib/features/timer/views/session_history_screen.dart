import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/timer_session.dart';
import '../../../core/providers/repositories.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/models/sound_option.dart';

final _sessionsProvider = Provider<List<TimerSession>>(
  (ref) => ref.watch(sessionRepositoryProvider).getAll(),
);

class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(_sessionsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Session history')),
      body: sessions.isEmpty
          ? _EmptyState(scheme: scheme)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: sessions.length,
              separatorBuilder: (_, index) => const SizedBox(height: 4),
              itemBuilder: (context, i) => _SessionTile(
                session: sessions[i],
                onDelete: () async {
                  await ref
                      .read(sessionRepositoryProvider)
                      .delete(sessions[i].id);
                  ref.invalidate(_sessionsProvider);
                },
              ),
            ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onDelete});

  final TimerSession session;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sound = SoundOption.findById(session.soundId);

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _StatusIcon(completed: session.completed, scheme: scheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DurationFormatter.label(session.duration),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(session.startedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withAlpha(130),
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    sound.displayName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withAlpha(130),
                        ),
                  ),
                  if (session.interval != null)
                    Text(
                      '${DurationFormatter.label(session.interval!)} intervals',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withAlpha(130),
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Today at $h:$m';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.completed, required this.scheme});

  final bool completed;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: completed
            ? scheme.primary.withAlpha(25)
            : scheme.secondary.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(
        completed ? Icons.check_circle_outline : Icons.stop_circle_outlined,
        color: completed ? scheme.primary : scheme.secondary,
        size: 20,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.self_improvement_outlined,
            size: 64,
            color: scheme.onSurface.withAlpha(60),
          ),
          const SizedBox(height: 16),
          Text(
            'Your first sit awaits',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface.withAlpha(100),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Completed sessions will appear here.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withAlpha(80),
                ),
          ),
        ],
      ),
    );
  }
}
