class SoundOption {
  const SoundOption({
    required this.id,
    required this.displayName,
    required this.assetPath,
    required this.androidRawName,
  });

  final String id;
  final String displayName;
  final String assetPath;
  final String androidRawName; // filename without extension, for notification channels

  static const List<SoundOption> all = [
    SoundOption(
      id: 'tibetan_bowl',
      displayName: 'Tibetan Bowl',
      assetPath: 'assets/audio/tibetan_bowl_1.mp3',
      androidRawName: 'tibetan_bowl_1',
    ),
    SoundOption(
      id: 'meditation_bowl',
      displayName: 'Meditation Bowl',
      assetPath: 'assets/audio/meditation_bowl.mp3',
      androidRawName: 'meditation_bowl',
    ),
    SoundOption(
      id: 'zen_bell',
      displayName: 'Zen Bell',
      assetPath: 'assets/audio/zen_notification.mp3',
      androidRawName: 'zen_notification',
    ),
    SoundOption(
      id: 'singing_bowl',
      displayName: 'Singing Bowl',
      assetPath: 'assets/audio/cuenco_zen.mp3',
      androidRawName: 'cuenco_zen',
    ),
    SoundOption(
      id: 'gentle_gong',
      displayName: 'Gentle Gong',
      assetPath: 'assets/audio/gentle_gong.mp3',
      androidRawName: 'gentle_gong',
    ),
  ];

  static SoundOption findById(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
