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
    ref.listen<List<MeditationTimer>>(
      meditationTimersProvider,
      (previous, next) {
        final current = state;
        if (current == null) {
          if (next.isNotEmpty) {
            state = next.first;
          }
        } else {
          // Keep current selected if it still exists in the list (possibly updated)
          final matches = next.where((t) => t.id == current.id);
          if (matches.isNotEmpty) {
            state = matches.first;
          } else {
            state = next.isNotEmpty ? next.first : null;
          }
        }
      },
      fireImmediately: false,
    );

    final initialTimers = ref.read(meditationTimersProvider);
    return initialTimers.isNotEmpty ? initialTimers.first : null;
  }

  void select(MeditationTimer? timer) {
    state = timer;
  }
}

final selectedTimerProvider = NotifierProvider<SelectedTimerNotifier, MeditationTimer?>(
  SelectedTimerNotifier.new,
);
