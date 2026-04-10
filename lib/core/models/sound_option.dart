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
      id: 'bell_tibetan',
      displayName: 'Tibetan Bell',
      assetPath: 'assets/audio/bell_tibetan.ogg',
      androidRawName: 'bell_tibetan',
    ),
    SoundOption(
      id: 'bowl_singing',
      displayName: 'Singing Bowl',
      assetPath: 'assets/audio/bowl_singing.ogg',
      androidRawName: 'bowl_singing',
    ),
    SoundOption(
      id: 'chime_soft',
      displayName: 'Soft Chime',
      assetPath: 'assets/audio/chime_soft.ogg',
      androidRawName: 'chime_soft',
    ),
    SoundOption(
      id: 'chime_crystal',
      displayName: 'Crystal Chime',
      assetPath: 'assets/audio/chime_crystal.ogg',
      androidRawName: 'chime_crystal',
    ),
    SoundOption(
      id: 'nature_rain',
      displayName: 'Rain Drop',
      assetPath: 'assets/audio/nature_rain.ogg',
      androidRawName: 'nature_rain',
    ),
  ];

  static SoundOption findById(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
