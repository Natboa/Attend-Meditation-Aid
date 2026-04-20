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
    SoundOption(
      id: 'zen_chime',
      displayName: 'Zen Chime',
      assetPath: 'assets/audio/zen.mp3',
      androidRawName: 'zen',
    ),
    SoundOption(
      id: 'crystal_gong',
      displayName: 'Crystal Gong',
      assetPath: 'assets/audio/bmw_gong.mp3',
      androidRawName: 'bmw_gong',
    ),
    SoundOption(
      id: 'chi_gong',
      displayName: 'Chi Gong',
      assetPath: 'assets/audio/chigong.mp3',
      androidRawName: 'chigong',
    ),
    SoundOption(
      id: 'nepal_echo',
      displayName: 'Nepal Echo',
      assetPath: 'assets/audio/nepal_gong_mit_echo.mp3',
      androidRawName: 'nepal_gong_mit_echo',
    ),
    SoundOption(
      id: 'bamboo_flute',
      displayName: 'Bamboo Flute',
      assetPath: 'assets/audio/flute.mp3',
      androidRawName: 'flute',
    ),
    SoundOption(
      id: 'deep_meditation',
      displayName: 'Deep Meditation',
      assetPath: 'assets/audio/meditation.mp3',
      androidRawName: 'meditation',
    ),
  ];

  static SoundOption findById(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
