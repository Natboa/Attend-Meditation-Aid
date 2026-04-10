import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/notification_config.dart';
import '../../../core/providers/repositories.dart';
import '../../../core/repositories/notification_config_repository.dart';
import '../../../core/services/background_scheduler.dart';
import '../../../core/services/scheduler_service.dart';

final notificationConfigRepositoryProvider =
    Provider<NotificationConfigRepository>(
  (ref) => NotificationConfigRepository(ref.watch(sharedPreferencesProvider)),
);

class NotificationConfigNotifier extends Notifier<NotificationConfig> {
  @override
  NotificationConfig build() =>
      ref.read(notificationConfigRepositoryProvider).load();

  Future<void> setEnabled(bool value) async {
    state = NotificationConfig(
      enabled: value,
      activeDays: state.activeDays,
      startHour: state.startHour,
      endHour: state.endHour,
      frequencyPerDay: state.frequencyPerDay,
      bellSoundId: state.bellSoundId,
      dailyGathaEnabled: state.dailyGathaEnabled,
      dailyGathaHour: state.dailyGathaHour,
    );
    await _persist();
    if (value) {
      await triggerDailyScheduler();
    } else {
      await SchedulerService.instance.cancelAllBells();
      await cancelDailyScheduler();
    }
  }

  Future<void> updateDays(List<int> days) async {
    state = _copyWith(activeDays: days);
    await _persistAndReschedule();
  }

  Future<void> updateHourRange(int start, int end) async {
    state = _copyWith(startHour: start, endHour: end);
    await _persistAndReschedule();
  }

  Future<void> updateFrequency(int count) async {
    state = _copyWith(frequencyPerDay: count);
    await _persistAndReschedule();
  }

  Future<void> updateBellSound(String soundId) async {
    state = _copyWith(bellSoundId: soundId);
    await _persistAndReschedule();
  }

  Future<void> _persistAndReschedule() async {
    await _persist();
    if (state.enabled) {
      await SchedulerService.instance.rescheduleBells(state);
    }
  }

  Future<void> _persist() =>
      ref.read(notificationConfigRepositoryProvider).save(state);

  NotificationConfig _copyWith({
    bool? enabled,
    List<int>? activeDays,
    int? startHour,
    int? endHour,
    int? frequencyPerDay,
    String? bellSoundId,
    bool? dailyGathaEnabled,
    int? dailyGathaHour,
  }) =>
      NotificationConfig(
        enabled: enabled ?? state.enabled,
        activeDays: activeDays ?? state.activeDays,
        startHour: startHour ?? state.startHour,
        endHour: endHour ?? state.endHour,
        frequencyPerDay: frequencyPerDay ?? state.frequencyPerDay,
        bellSoundId: bellSoundId ?? state.bellSoundId,
        dailyGathaEnabled: dailyGathaEnabled ?? state.dailyGathaEnabled,
        dailyGathaHour: dailyGathaHour ?? state.dailyGathaHour,
      );
}

final notificationConfigProvider =
    NotifierProvider<NotificationConfigNotifier, NotificationConfig>(
  NotificationConfigNotifier.new,
);
