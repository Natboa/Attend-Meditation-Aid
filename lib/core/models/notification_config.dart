import 'package:hive_flutter/hive_flutter.dart';

part 'notification_config.g.dart';

@HiveType(typeId: 1)
class NotificationConfig extends HiveObject {
  NotificationConfig({
    required this.enabled,
    required this.activeDays,
    required this.startHour,
    required this.endHour,
    required this.frequencyPerDay,
    required this.bellSoundId,
    required this.dailyGathaEnabled,
    required this.dailyGathaHour,
  });

  @HiveField(0)
  bool enabled;

  /// ISO weekday: 1 = Monday, 7 = Sunday.
  @HiveField(1)
  List<int> activeDays;

  @HiveField(2)
  int startHour;

  @HiveField(3)
  int endHour;

  @HiveField(4)
  int frequencyPerDay;

  /// Sound used for mindfulness bells — independent of timer sound.
  @HiveField(5)
  String bellSoundId;

  @HiveField(6)
  bool dailyGathaEnabled;

  @HiveField(7)
  int dailyGathaHour;

  factory NotificationConfig.defaults() => NotificationConfig(
        enabled: false,
        activeDays: [1, 2, 3, 4, 5], // Mon–Fri
        startHour: 9,
        endHour: 18,
        frequencyPerDay: 3,
        bellSoundId: 'bell_tibetan',
        dailyGathaEnabled: false,
        dailyGathaHour: 7,
      );
}
