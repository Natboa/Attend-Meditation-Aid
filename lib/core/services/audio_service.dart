import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import '../models/sound_option.dart';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  AudioPlayer? _player;
  Timer? _previewTimer;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
    ));
  }

  Future<void> playBell(String soundId) async {
    final sound = SoundOption.findById(soundId);
    await _playAsset(sound.assetPath);
  }

  Future<void> previewSound(String soundId) async {
    _previewTimer?.cancel();
    final sound = SoundOption.findById(soundId);
    await _playAsset(sound.assetPath);
    _previewTimer = Timer(const Duration(seconds: 3), stop);
  }

  Future<void> stop() async {
    _previewTimer?.cancel();
    await _player?.stop();
  }

  Future<void> dispose() async {
    _previewTimer?.cancel();
    await _player?.dispose();
    _player = null;
  }

  Future<void> _playAsset(String assetPath) async {
    await _player?.stop();
    _player ??= AudioPlayer();
    await _player!.setAsset(assetPath);
    await _player!.play();
  }
}
