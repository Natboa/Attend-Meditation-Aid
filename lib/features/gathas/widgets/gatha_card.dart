import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/gatha.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/gatha_providers.dart';

class GathaCard extends ConsumerWidget {
  const GathaCard({super.key, required this.gatha});

  final Gatha gatha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/library/${gatha.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gatha.title,
                      style: AppTextStyles.heading(context).copyWith(
                        fontSize: 16,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      gatha.preview(lines: 2),
                      style: AppTextStyles.poem(context).copyWith(
                        fontSize: 13,
                        color: scheme.onSurface.withAlpha(180),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (gatha.attribution != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '— ${gatha.attribution}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withAlpha(100),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  gatha.isFavourite ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: gatha.isFavourite
                      ? scheme.secondary
                      : scheme.onSurface.withAlpha(80),
                ),
                onPressed: () =>
                    ref.read(favouriteNotifierProvider.notifier).toggle(gatha.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
