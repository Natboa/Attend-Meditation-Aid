import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gatha.dart';

class GathaRepository {
  GathaRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _favKey = 'gatha_favourites';
  static const _assetPath = 'assets/data/gathas.json';

  List<Gatha>? _cache;

  Future<List<Gatha>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final favIds = _loadFavouriteIds();
    _cache = (json['gathas'] as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      return Gatha.fromJson(map).copyWith(isFavourite: favIds.contains(map['id']));
    }).toList();
    return _cache!;
  }

  Set<String> _loadFavouriteIds() {
    final raw = _prefs.getString(_favKey);
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  Future<void> toggleFavourite(String id) async {
    final ids = _loadFavouriteIds();
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    await _prefs.setString(_favKey, ids.join(','));

    // Update cache in place
    if (_cache != null) {
      _cache = _cache!
          .map((g) => g.id == id ? g.copyWith(isFavourite: ids.contains(id)) : g)
          .toList();
    }
  }

  bool isFavourite(String id) => _loadFavouriteIds().contains(id);

  /// Deterministic poem of the day — changes at midnight, stable across app restarts.
  Future<Gatha?> gathaOfTheDay() async {
    final all = await loadAll();
    if (all.isEmpty) return null;
    final epoch = DateTime(2026, 1, 1);
    final today = DateTime.now();
    final dayIndex = today.difference(epoch).inDays.abs() % all.length;
    return all[dayIndex];
  }
}
