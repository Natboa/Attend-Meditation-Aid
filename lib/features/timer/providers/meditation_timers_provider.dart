import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/meditation_timer.dart';
import '../../../core/providers/repositories.dart';

class MeditationTimersNotifier extends Notifier<List<MeditationTimer>> {
  @override
  List<MeditationTimer> build() {
    return ref.watch(meditationTimerRepositoryProvider).load();
  }

  Future<void> addTimer(MeditationTimer timer) async {
    final list = [...state, timer];
    state = list;
    await ref.read(meditationTimerRepositoryProvider).saveAll(list);
  }

  Future<void> updateTimer(MeditationTimer timer) async {
    final list = state.map((t) => t.id == timer.id ? timer : t).toList();
    state = list;
    await ref.read(meditationTimerRepositoryProvider).saveAll(list);
  }

  Future<void> deleteTimer(String id) async {
    final list = state.where((t) => t.id != id).toList();
    state = list;
    await ref.read(meditationTimerRepositoryProvider).saveAll(list);
  }
}

final meditationTimersProvider = NotifierProvider<MeditationTimersNotifier, List<MeditationTimer>>(
  MeditationTimersNotifier.new,
);

class SelectedTimerNotifier extends Notifier<MeditationTimer?> {
  @override
  MeditationTimer? build() {
    final timers = ref.watch(meditationTimersProvider);
    if (timers.isEmpty) return null;
    
    // Keep current selected if it still exists in the list (possibly updated)
    final current = state;
    if (current != null) {
      final matches = timers.where((t) => t.id == current.id);
      if (matches.isNotEmpty) {
        return matches.first;
      }
    }
    return timers.first;
  }

  void select(MeditationTimer? timer) {
    state = timer;
  }
}

final selectedTimerProvider = NotifierProvider<SelectedTimerNotifier, MeditationTimer?>(
  SelectedTimerNotifier.new,
);
