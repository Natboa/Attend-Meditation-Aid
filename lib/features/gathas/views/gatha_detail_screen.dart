import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/gatha_providers.dart';

class GathaDetailScreen extends ConsumerWidget {
  const GathaDetailScreen({super.key, required this.gathaId});

  final String gathaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(gathaListProvider);
    final scheme = Theme.of(context).colorScheme;

    return allAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (all) {
        final gatha = all.firstWhere(
          (g) => g.id == gathaId,
          orElse: () => all.first,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              gatha.title,
              style: AppTextStyles.heading(context),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  gatha.isFavourite ? Icons.favorite : Icons.favorite_border,
                  color: gatha.isFavourite ? scheme.secondary : null,
                ),
                tooltip: gatha.isFavourite
                    ? 'Remove from favourites'
                    : 'Add to favourites',
                onPressed: () => ref
                    .read(favouriteNotifierProvider.notifier)
                    .toggle(gatha.id),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Copy poem',
                onPressed: () {
                  final text = '${gatha.title}\n\n${gatha.body}'
                      '${gatha.attribution != null ? '\n\n— ${gatha.attribution}' : ''}';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gatha.title,
                    style: AppTextStyles.heading(context).copyWith(
                      fontSize: 24,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    gatha.body,
                    style: AppTextStyles.poem(context).copyWith(
                      fontSize: 17,
                      height: 1.9,
                      color: scheme.onSurface.withAlpha(210),
                    ),
                  ),
                  if (gatha.attribution != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      '— ${gatha.attribution}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withAlpha(130),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: gatha.tags
                        .map((tag) => Chip(
                              label: Text(tag,
                                  style: const TextStyle(fontSize: 12)),
                              backgroundColor:
                                  scheme.primary.withAlpha(20),
                              side: BorderSide(
                                  color: scheme.primary.withAlpha(60)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 0),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
