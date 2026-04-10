class NotificationConfig {
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

  bool enabled;

  /// ISO weekday: 1 = Monday, 7 = Sunday.
  List<int> activeDays;

  int startHour;
  int endHour;
  int frequencyPerDay;

  /// Sound used for mindfulness bells — independent of timer sound.
  String bellSoundId;

  bool dailyGathaEnabled;
  int dailyGathaHour;

  factory NotificationConfig.defaults() => NotificationConfig(
        enabled: false,
        activeDays: [1, 2, 3, 4, 5], // Mon–Fri
        startHour: 9,
        endHour: 18,
        frequencyPerDay: 3,
        bellSoundId: 'tibetan_bowl',
        dailyGathaEnabled: false,
        dailyGathaHour: 7,
      );
}
