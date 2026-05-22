class MeditationTimer {
  final String id;
  final Duration? duration;
  final Duration? interval;
  final String soundId;

  const MeditationTimer({
    required this.id,
    this.duration,
    this.interval,
    required this.soundId,
  });

  MeditationTimer copyWith({
    String? id,
    Duration? duration,
    Duration? interval,
    String? soundId,
  }) {
    return MeditationTimer(
      id: id ?? this.id,
      duration: duration ?? this.duration,
      interval: interval ?? this.interval,
      soundId: soundId ?? this.soundId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'duration_seconds': duration?.inSeconds,
      'interval_seconds': interval?.inSeconds,
      'sound_id': soundId,
    };
  }

  factory MeditationTimer.fromJson(Map<String, dynamic> json) {
    final durSec = json['duration_seconds'] as int?;
    final intSec = json['interval_seconds'] as int?;
    return MeditationTimer(
      id: json['id'] as String,
      duration: durSec != null ? Duration(seconds: durSec) : null,
      interval: intSec != null ? Duration(seconds: intSec) : null,
      soundId: json['sound_id'] as String? ?? 'tibetan_bowl',
    );
  }
}
