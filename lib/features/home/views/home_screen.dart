import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../gathas/providers/gatha_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attend',
          style: AppTextStyles.heading(context).copyWith(
            color: scheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GreetingCard(scheme: scheme),
              const SizedBox(height: 20),
              const _PoemOfDayCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.scheme});

  final ColorScheme scheme;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning.';
    if (h < 17) return 'Good afternoon.';
    return 'Good evening.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(),
          style: AppTextStyles.display(context).copyWith(
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Be here. Be now.',
          style: AppTextStyles.body(context).copyWith(
            color: scheme.onSurface.withAlpha(140),
          ),
        ),
      ],
    );
  }
}

class _PoemOfDayCard extends ConsumerWidget {
  const _PoemOfDayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final gathaAsync = ref.watch(gathaOfTheDayProvider);

    return gathaAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (gatha) {
        if (gatha == null) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories_outlined,
                        size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Poem of the day',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
                if (gatha.hasRealTitle) ...[
                  const SizedBox(height: 12),
                  Text(
                    gatha.title,
                    style: AppTextStyles.heading(context).copyWith(
                      color: scheme.onSurface,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  const SizedBox(height: 12),
                ],
                Text(
                  gatha.preview(lines: 3),
                  style: AppTextStyles.poem(context).copyWith(
                    color: scheme.onSurface.withAlpha(200),
                  ),
                ),
                if (gatha.attribution != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '— ${gatha.attribution}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withAlpha(120),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.push('/library/${gatha.id}'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Read full poem →',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
