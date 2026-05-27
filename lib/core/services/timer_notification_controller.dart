import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Singleton that bridges notification action taps to the running TimerNotifier.
///
/// TimerNotifier registers [onPause]/[onResume]/[onStop] when a session starts
/// and clears them on stop/finish. NotificationService calls [handleAction]
/// when the user taps a notification action button.
class TimerNotificationController {
  TimerNotificationController._() {
    _initPort();
  }
  
  static final TimerNotificationController instance =
      TimerNotificationController._();

  static const String _portName = 'attend_timer_notification_port';
  ReceivePort? _receivePort;

  VoidCallback? onPause;
  VoidCallback? onResume;
  VoidCallback? onStop;

  void _initPort() {
    _receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _portName);
    debugPrint('APP ISOLATE: Registered IsolateNameServer for $_portName');
    
    _receivePort!.listen((message) {
      debugPrint('APP ISOLATE: Received message on port: $message');
      if (message is String) {
        handleAction(message);
      }
    });
  }

  void handleAction(String? actionId) {
    debugPrint('APP ISOLATE: handleAction invoked with $actionId');
    switch (actionId) {
      case 'timer_pause':
        onPause?.call();
        break;
      case 'timer_resume':
        onResume?.call();
        break;
      case 'timer_stop':
        onStop?.call();
        break;
    }
  }

  void clear() {
    onPause = null;
    onResume = null;
    onStop = null;
  }
}
