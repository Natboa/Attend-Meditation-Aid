import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  static const _batteryChannel = MethodChannel('attend/battery');

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Returns true if POST_NOTIFICATIONS is granted (Android 13+).
  /// On API < 33 this always returns true.
  Future<bool> requestNotificationPermission() async {
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Returns true if SCHEDULE_EXACT_ALARM is available.
  Future<bool> hasExactAlarmPermission() async {
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.canScheduleExactNotifications();
    return result ?? false;
  }

  /// Returns true if the app is already exempt from battery optimizations.
  Future<bool> isBatteryOptimizationIgnored() async {
    final result =
        await _batteryChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
    return result ?? false;
  }

  /// Opens the system dialog asking the user to exempt Attend from battery optimizations.
  /// Call this during onboarding or when the user first enables mindfulness bells.
  Future<void> requestBatteryOptimizationExemption() async {
    await _batteryChannel.invokeMethod('requestIgnoreBatteryOptimizations');
  }

  /// Shows a dialog guiding the user to grant SCHEDULE_EXACT_ALARM in system settings.
  Future<void> showExactAlarmDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exact alarm permission needed'),
        content: const Text(
          'To deliver mindfulness bells at precise times, Attend needs '
          '"Alarms & reminders" permission.\n\n'
          'Tap OK to open system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _plugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.requestExactAlarmsPermission();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
