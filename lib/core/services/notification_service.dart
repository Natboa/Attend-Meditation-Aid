import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/sound_option.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _timerChannelId = 'meditation_timer';
  static const _gathaChannelId = 'daily_gatha';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Create static channels
    await _createChannel(
      id: _timerChannelId,
      name: 'Meditation timer',
      description: 'Foreground service notification while the timer runs',
      importance: Importance.low,
      sound: null,
    );

    await _createChannel(
      id: _gathaChannelId,
      name: 'Daily poem',
      description: 'Morning poem of the day',
      importance: Importance.defaultImportance,
      sound: null,
    );

    _initialized = true;
  }

  /// Ensures a per-sound mindfulness bell channel exists.
  Future<void> ensureMindfulnessChannel(String soundId) async {
    final sound = SoundOption.findById(soundId);
    await _createChannel(
      id: _mindfulnessChannelId(soundId),
      name: 'Mindfulness bell — ${sound.displayName}',
      description: 'Random mindfulness bell reminders',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound(sound.androidRawName),
    );
  }

  static String _mindfulnessChannelId(String soundId) =>
      'mindfulness_bell_$soundId';

  /// Posts a mindfulness bell notification then immediately cancels it,
  /// so the user hears the bell but sees nothing in the shade.
  Future<void> showMindfulnessBell(String soundId) async {
    await ensureMindfulnessChannel(soundId);

    const notifId = 9001;
    final androidDetails = AndroidNotificationDetails(
      _mindfulnessChannelId(soundId),
      'Mindfulness bell',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      ongoing: false,
      silent: false,
      // No title/body → invisible content, sound only
      styleInformation: const BigTextStyleInformation(''),
    );

    await _plugin.show(
      notifId,
      null,
      null,
      NotificationDetails(android: androidDetails),
    );

    // Cancel immediately — bell sound already started playing via channel
    await Future.delayed(const Duration(milliseconds: 300));
    await _plugin.cancel(notifId);
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> _createChannel({
    required String id,
    required String name,
    required String description,
    required Importance importance,
    AndroidNotificationSound? sound,
  }) async {
    final channel = AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: importance,
      sound: sound,
      playSound: sound != null,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
