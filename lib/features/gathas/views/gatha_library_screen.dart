import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/gatha_providers.dart';
import '../widgets/gatha_card.dart';

class GathaLibraryScreen extends ConsumerWidget {
  const GathaLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Library', style: AppTextStyles.heading(context)),
        actions: [
          _FavouriteToggle(),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(),
          _TagFilter(),
          Expanded(child: _GathaList()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _FavouriteToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsOnly = ref.watch(gathaShowFavouritesOnlyProvider);
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: favsOnly ? 'Show all' : 'Favourites only',
      icon: Icon(
        favsOnly ? Icons.favorite : Icons.favorite_border,
        color: favsOnly ? scheme.secondary : null,
      ),
      onPressed: () => ref
          .read(gathaShowFavouritesOnlyProvider.notifier)
          .state = !favsOnly,
    );
  }
}

// ---------------------------------------------------------------------------

class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search poems…',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        ),
        onChanged: (v) =>
            ref.read(gathaSearchQueryProvider.notifier).state = v,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TagFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(allTagsProvider);
    final selectedTag = ref.watch(gathaSelectedTagProvider);
    final scheme = Theme.of(context).colorScheme;

    return tagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (tags) => SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: tags.length,
          itemBuilder: (context, i) {
            final tag = tags[i];
            final selected = tag == selectedTag;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(tag,
                    style: TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (_) => ref
                    .read(gathaSelectedTagProvider.notifier)
                    .state = selected ? null : tag,
                selectedColor: scheme.primary.withAlpha(30),
                checkmarkColor: scheme.primary,
                side: BorderSide(
                  color: selected
                      ? scheme.primary
                      : scheme.outline.withAlpha(100),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _GathaList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredGathasProvider);
    final scheme = Theme.of(context).colorScheme;

    return filtered.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading poems: $e')),
      data: (gathas) {
        if (gathas.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off,
                    size: 48, color: scheme.onSurface.withAlpha(60)),
                const SizedBox(height: 12),
                Text(
                  'No poems found',
                  style: AppTextStyles.body(context).copyWith(
                    color: scheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 24),
          itemCount: gathas.length,
          itemBuilder: (context, i) => GathaCard(gatha: gathas[i]),
        );
      },
    );
  }
}
