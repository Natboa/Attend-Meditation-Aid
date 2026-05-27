import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart'; // added for debugPrint
import 'package:flutter/material.dart'; // added for WidgetsFlutterBinding
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sound_option.dart';
import 'timer_notification_controller.dart';

@pragma('vm:entry-point')
Future<void> _notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('APP ISOLATE: _notificationTapBackground called with action ${response.actionId}');
  
  // Eagerly update the notification UI before the main isolate wakes up.
  if (response.actionId != null && response.payload != null && response.payload!.isNotEmpty) {
    try {
      final int remainingSeconds = int.tryParse(response.payload!) ?? 0;
      final remaining = Duration(seconds: remainingSeconds);
      final plugin = FlutterLocalNotificationsPlugin();
      if (response.actionId == 'timer_pause') {
        await plugin.show(
          NotificationService._timerNotifId,
          NotificationService.formatRemaining(remaining),
          'Paused',
          NotificationDetails(android: NotificationService.pausedDetails()),
          payload: response.payload,
        );
      } else if (response.actionId == 'timer_resume') {
        await plugin.show(
          NotificationService._timerNotifId,
          NotificationService.formatRemaining(remaining),
          'Session in progress',
          NotificationDetails(android: NotificationService.runningDetails()),
          payload: response.payload,
        );
      }
    } catch (e) {
      debugPrint('Eager notification update failed: $e');
    }
  }

  // Try sending to the main isolate first
  final SendPort? sendPort =
      IsolateNameServer.lookupPortByName('attend_timer_notification_port');
  
  debugPrint('APP ISOLATE: sendPort found? ${sendPort != null}');
  
  if (sendPort != null) {
    sendPort.send(response.actionId);
  } else {
    // Fallback if we happen to already be in the main isolate
    TimerNotificationController.instance.handleAction(response.actionId);
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _notifChannel = MethodChannel('attend/notifications');
  static const _cacheClearedKey = 'notification_cache_cleared_v2'; // v1 used wrong prefs file

  static const _gathaChannelId = 'daily_gatha';
  static const _timerChannelId = 'timer_session';
  static const _timerNotifId = 9002;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    await _createChannel(
      id: _gathaChannelId,
      name: 'Daily poem',
      description: 'Morning poem of the day',
      importance: Importance.defaultImportance,
      sound: null,
    );

    // Silent channel for the timer — no sound on show/update
    await _createChannel(
      id: _timerChannelId,
      name: 'Timer session',
      description: 'Active meditation timer with pause and stop controls',
      importance: Importance.low,
      sound: null,
    );

    _initialized = true;
    await _clearCorruptCacheOnce();
  }

  /// One-time migration: clears the flutter_local_notifications SharedPreferences
  /// cache that may contain corrupt styleInformation entries (Missing type parameter).
  /// Safe to clear — scheduled alarms still fire via Intent extras; the cache is
  /// only used for cancel() and pendingNotificationRequests().
  Future<void> _clearCorruptCacheOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_cacheClearedKey) == true) return;
      await _notifChannel.invokeMethod<void>('clearScheduledCache');
      await prefs.setBool(_cacheClearedKey, true);
    } catch (_) {
      // Not critical — runs only from the UI isolate where the channel is available.
    }
  }

  // Set to true when we eagerly update the notification in-handler so the
  // redundant call from pause()/resume() in the state chain is skipped.
  static bool _skipNextTimerUpdate = false;

  static void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      final remainingSeconds = int.tryParse(response.payload!) ?? 0;
      final remaining = Duration(seconds: remainingSeconds);
      if (response.actionId == 'timer_pause') {
        _skipNextTimerUpdate = true;
        instance._plugin.show(
          _timerNotifId,
          formatRemaining(remaining),
          'Paused',
          NotificationDetails(android: pausedDetails()),
          payload: response.payload,
        );
      } else if (response.actionId == 'timer_resume') {
        _skipNextTimerUpdate = true;
        instance._plugin.show(
          _timerNotifId,
          formatRemaining(remaining),
          'Session in progress',
          NotificationDetails(android: runningDetails()),
          payload: response.payload,
        );
      }
    }
    TimerNotificationController.instance.handleAction(response.actionId);
    // Safety reset in case handleAction didn't consume the flag
    // (e.g. onPause/onResume wasn't registered).
    Future.microtask(() => _skipNextTimerUpdate = false);
  }

  // ── Timer notification ────────────────────────────────────────────────────

  /// Shows an ongoing timer notification. Call when the session starts.
  Future<void> showTimerNotification({
    required Duration remaining,
  }) async {
    await _plugin.show(
      _timerNotifId,
      formatRemaining(remaining),
      'Session in progress',
      NotificationDetails(android: runningDetails()),
      payload: remaining.inSeconds.toString(),
    );
  }

  /// Updates the notification for a pause state.
  Future<void> pauseTimerNotification(Duration remaining) async {
    if (_skipNextTimerUpdate) {
      _skipNextTimerUpdate = false;
      return; // already updated eagerly in _onNotificationResponse
    }
    await _plugin.show(
      _timerNotifId,
      formatRemaining(remaining),
      'Paused',
      NotificationDetails(android: pausedDetails()),
      payload: remaining.inSeconds.toString(),
    );
  }

  /// Updates the notification back to the running countdown.
  Future<void> resumeTimerNotification(Duration remaining) async {
    if (_skipNextTimerUpdate) {
      _skipNextTimerUpdate = false;
      return; // already updated eagerly in _onNotificationResponse
    }
    await _plugin.show(
      _timerNotifId,
      formatRemaining(remaining),
      'Session in progress',
      NotificationDetails(android: runningDetails()),
      payload: remaining.inSeconds.toString(),
    );
  }

  /// Cancels the timer notification. Call when session ends.
  Future<void> cancelTimerNotification() async {
    await _plugin.cancel(_timerNotifId);
  }

  static AndroidNotificationDetails runningDetails() {
    return const AndroidNotificationDetails(
      _timerChannelId,
      'Timer session',
      channelDescription: 'Active meditation timer',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      silent: true,
      visibility: NotificationVisibility.public,
      onlyAlertOnce: true,
      actions: [
        AndroidNotificationAction('timer_pause', 'Pause', cancelNotification: false),
        AndroidNotificationAction('timer_stop', 'Stop', cancelNotification: false),
      ],
    );
  }

  static AndroidNotificationDetails pausedDetails() {
    return const AndroidNotificationDetails(
      _timerChannelId,
      'Timer session',
      channelDescription: 'Active meditation timer',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      silent: true,
      visibility: NotificationVisibility.public,
      onlyAlertOnce: true,
      actions: [
        AndroidNotificationAction('timer_resume', 'Resume', cancelNotification: false),
        AndroidNotificationAction('timer_stop', 'Stop', cancelNotification: false),
      ],
    );
  }

  static String formatRemaining(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s remaining';
  }

  // ── Mindfulness bells ─────────────────────────────────────────────────────

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

  // v2 suffix forces fresh channel creation — old channels had sound=null due to
  // being created before the raw audio files were present in the build.
  static String _mindfulnessChannelId(String soundId) =>
      'mindfulness_bell_v2_$soundId';

  /// Posts a mindfulness bell notification then auto-dismisses it via
  /// [timeoutAfter], so the user hears the bell but sees nothing in the shade.
  /// This avoids calling cancel(), which would trigger loadScheduledNotifications
  /// and crash on any corrupt cache entries.
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
      timeoutAfter: 4000, // auto-dismiss after 4 s — sound plays fully, then clears from shade
    );

    await _plugin.show(
      notifId,
      null,
      null,
      NotificationDetails(android: androidDetails),
    );
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
