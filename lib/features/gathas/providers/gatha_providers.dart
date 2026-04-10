import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/gatha.dart';
import '../../../core/providers/repositories.dart';

// ---------------------------------------------------------------------------
// Raw list (async, loads once from assets)
// ---------------------------------------------------------------------------

final gathaListProvider = FutureProvider<List<Gatha>>((ref) {
  return ref.watch(gathaRepositoryProvider).loadAll();
});

// ---------------------------------------------------------------------------
// Poem of the day
// ---------------------------------------------------------------------------

final gathaOfTheDayProvider = FutureProvider<Gatha?>((ref) {
  return ref.watch(gathaRepositoryProvider).gathaOfTheDay();
});

// ---------------------------------------------------------------------------
// Search / filter state
// ---------------------------------------------------------------------------

final gathaSearchQueryProvider = StateProvider<String>((ref) => '');
final gathaSelectedTagProvider = StateProvider<String?>((ref) => null);
final gathaShowFavouritesOnlyProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Filtered list
// ---------------------------------------------------------------------------

final filteredGathasProvider = Provider<AsyncValue<List<Gatha>>>((ref) {
  final allAsync = ref.watch(gathaListProvider);
  final query = ref.watch(gathaSearchQueryProvider).toLowerCase().trim();
  final tag = ref.watch(gathaSelectedTagProvider);
  final favsOnly = ref.watch(gathaShowFavouritesOnlyProvider);

  return allAsync.whenData((all) {
    var result = all;
    if (favsOnly) result = result.where((g) => g.isFavourite).toList();
    if (tag != null) result = result.where((g) => g.tags.contains(tag)).toList();
    if (query.isNotEmpty) {
      result = result
          .where((g) =>
              g.title.toLowerCase().contains(query) ||
              g.body.toLowerCase().contains(query) ||
              (g.attribution?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    return result;
  });
});

// ---------------------------------------------------------------------------
// All distinct tags
// ---------------------------------------------------------------------------

final allTagsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final allAsync = ref.watch(gathaListProvider);
  return allAsync.whenData((all) {
    final tags = <String>{};
    for (final g in all) {
      tags.addAll(g.tags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  });
});

// ---------------------------------------------------------------------------
// Favourite toggle notifier
// ---------------------------------------------------------------------------

class FavouriteNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggle(String id) async {
    await ref.read(gathaRepositoryProvider).toggleFavourite(id);
    // Invalidate the list so UI rebuilds with updated isFavourite flags
    ref.invalidate(gathaListProvider);
  }
}

final favouriteNotifierProvider =
    NotifierProvider<FavouriteNotifier, void>(FavouriteNotifier.new);
