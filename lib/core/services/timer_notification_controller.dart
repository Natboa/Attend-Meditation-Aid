import 'package:flutter/foundation.dart';

/// Singleton that bridges notification action taps to the running TimerNotifier.
///
/// TimerNotifier registers [onPause]/[onResume]/[onStop] when a session starts
/// and clears them on stop/finish. NotificationService calls [handleAction]
/// when the user taps a notification action button.
class TimerNotificationController {
  TimerNotificationController._();
  static final TimerNotificationController instance =
      TimerNotificationController._();

  VoidCallback? onPause;
  VoidCallback? onResume;
  VoidCallback? onStop;

  void handleAction(String? actionId) {
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
