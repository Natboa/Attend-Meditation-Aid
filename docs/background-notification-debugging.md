# Background Notification Debugging — Attend

## The Problem

Mindfulness bell scheduled notifications (via `AlarmManager` + `ScheduledNotificationReceiver`) do not fire when the app is in the background or killed. The alarm fires (confirmed by `ActivityManager` logcat), but the notification never appears.

Immediate bells (`showMindfulnessBell` → `_plugin.show()`) work fine.

---

## Environment

- **Device:** Samsung S25 (SM S931B), Android 16 (API 36), Samsung One UI
- **Flutter:** debug mode via `flutter run`
- **ADB path:** `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`
- **Device ID:** `RZCY217X0MV`

---

## How to Connect & Run

```bash
# Check device is connected
flutter devices

# Run on device (installs + launches)
flutter run --device-id RZCY217X0MV

# Or just install without attaching
flutter install --device-id RZCY217X0MV
```

---

## Permissions — Must Re-Grant After Every Fresh Install

`flutter run` does `adb install -r` (replace), which preserves permissions across hot reloads and updates. But a **clean/uninstall** resets them.

```bash
ADB="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"

# Grant POST_NOTIFICATIONS (required on Android 13+)
"$ADB" -s RZCY217X0MV shell pm grant com.attend.attend android.permission.POST_NOTIFICATIONS

# Add to battery optimization whitelist (prevents Doze killing alarms)
"$ADB" -s RZCY217X0MV shell dumpsys deviceidle whitelist +com.attend.attend

# Verify permission state
"$ADB" -s RZCY217X0MV shell dumpsys package com.attend.attend | grep -A 2 "POST_NOTIF"

# Verify battery whitelist
"$ADB" -s RZCY217X0MV shell dumpsys deviceidle whitelist | grep attend
```

---

## How to Monitor Logs

### Stop stale Gradle daemons (if build hangs)
```bash
cd "C:/VS Code repos/Attend/android" && ./gradlew --stop
```

### Flutter stdout only (scheduling logs)
```bash
flutter logs --device-id RZCY217X0MV | grep -E "Attend:"
```

### System logcat — alarm firing + receiver
```bash
ADB="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"

# Watch for ScheduledNotificationReceiver + crashes
"$ADB" -s RZCY217X0MV logcat -v time | grep -E \
  "(ScheduledNotif|dexterous|attend\.attend|FATAL EXCEPTION|AndroidRuntime|BroadcastQueue.*attend)"
```

### Check notification channels on device
```bash
"$ADB" -s RZCY217X0MV shell dumpsys notification --noredact | grep -A 8 "mindfulness_bell"
```

### Check active app-level notification block
```bash
"$ADB" -s RZCY217X0MV shell dumpsys notification --noredact | grep -B 2 -A 5 "com.attend.attend"
```

---

## What Was Tried

### 1. `PlatformException: Missing type parameter` on `cancel()` — FIXED
**Cause:** `styleInformation: const BigTextStyleInformation('')` in `_scheduleBell` was stored in the SharedPreferences cache with Gson without a type discriminator. When `cancel()` called `loadScheduledNotifications`, deserialization crashed.

**Fix:**
- Removed `styleInformation` from `_scheduleBell` in `scheduler_service.dart`
- Used `timeoutAfter: 4000` in `showMindfulnessBell` instead of calling `_plugin.cancel()` (cancel also triggers the crash)
- Added try-catch around `_plugin.cancel()` in `cancelAllBells()`
- Added one-time native cache clear on first launch via `MethodChannel('attend/notifications')` → `clearScheduledCache` in `MainActivity.kt`

**Key detail:** The correct SharedPreferences file is `"scheduled_notifications"` (NOT `"notification_plugin_cache"`). Both the file name AND the key are `"scheduled_notifications"`.

---

### 2. `POST_NOTIFICATIONS` permission not granted — FIXED (via adb)
**Cause:** The runtime permission was never requested. `importance=NONE` showed in notification channel dump.

**Fix:** `adb shell pm grant com.attend.attend android.permission.POST_NOTIFICATIONS`

**Status:** Still granted (`granted=true` confirmed). The app's onboarding screen should request this via `flutter_local_notifications` permission request — verify this is wired up for production.

---

### 3. Notification channel created without sound — FIXED
**Cause:** `mindfulness_bell_tibetan_bowl` channel was created before audio files were present in `res/raw/`, so `sound=null`. Android notification channels are immutable after creation — sound can never be updated.

**Fix:** Versioned channel ID to force fresh creation:
```dart
// notification_service.dart
static String _mindfulnessChannelId(String soundId) =>
    'mindfulness_bell_v2_$soundId'; // v2 forces fresh channel with correct sound
```

---

### 4. `SchedulerService._scheduleBell` posting to wrong channel — FIXED
**Cause:** `_scheduleBell` used `'mindfulness_bell_$soundId'` (old channel, no `_v2_`), but `ensureMindfulnessChannel` creates `'mindfulness_bell_v2_$soundId'`. Android silently drops notifications posted to a non-existent channel.

**Fix:**
```dart
// scheduler_service.dart — _scheduleBell
final androidDetails = AndroidNotificationDetails(
  'mindfulness_bell_v2_$soundId', // must match channel from ensureMindfulnessChannel
  ...
```

**Status:** Fixed. Both channels (`mindfulness_bell_tibetan_bowl` and `mindfulness_bell_v2_tibetan_bowl`) now verified present on device with `mImportance=4`, correct sound, `mSoundMissingReason=0`.

---

### 5. Battery optimization / Doze whitelist
Added via `adb shell dumpsys deviceidle whitelist +com.attend.attend`. Did not resolve the issue.

---

### 6. Samsung Nandswap / process caching
Observed in logcat: Samsung aggressively swaps the app process to NAND flash (adj=850 = cached). The app process was eventually killed (`Killing 23979:com.attend.attend ... remove task`) when user swiped it from recents.

When the app process is dead, Android spawns a new process to run `ScheduledNotificationReceiver.onReceive`. This new process has a different PID.

---

## Current State

**Confirmed working:**
- AlarmManager fires exactly on schedule (`ActivityManager: Received BROADCAST intent ... ScheduledNotificationReceiver requestCode=998`)
- `POST_NOTIFICATIONS: granted=true`
- Channel `mindfulness_bell_v2_tibetan_bowl`: `mImportance=4`, sound configured, not deleted
- Immediate bell (`showMindfulnessBell`) works — notification id=9001 visible in `dumpsys notification`

**Not working:**
- Scheduled bell (id=998) via `ScheduledNotificationReceiver` — alarm fires but notification never appears

**Key observation:**
- No `ScheduledNotifReceiver` tag log lines appear in logcat when the alarm fires (receiver's success path has no logging)
- No `FATAL EXCEPTION` or `AndroidRuntime` crash seen — but this filter may need to be broader

---

## RESOLVED — Apr 15, 2026

### 7. Samsung One UI / Android 16 silently drops background notifications from `ScheduledNotificationReceiver` — FIXED

**Cause:** `ScheduledNotificationReceiver.onReceive()` from `flutter_local_notifications` ran without error and called `NotificationManagerCompat.notify()` successfully, but Samsung One UI 7 (Android 16) silently suppressed the notification at the system UI layer when posted from a background BroadcastReceiver process. No crash, no log, just nothing shown. The immediate bell (`_plugin.show()`) worked because it was posted from the active foreground Flutter engine process.

**Fix:** Replaced flutter_local_notifications' bell scheduling + delivery with native Android code:

| File | Role |
|------|------|
| `android/.../BellAlarmReceiver.kt` | BroadcastReceiver — handles AlarmManager alarm, posts notification directly via `NotificationManagerCompat` with full error logging |
| `android/.../BellPlugin.kt` | FlutterPlugin — exposes `attend/bells` MethodChannel (`scheduleBell` / `cancelBell`) |
| `android/.../MainActivity.kt` | Registers `BellPlugin` on engine start |
| `android/.../AndroidManifest.xml` | Declares `BellAlarmReceiver` (exported=false) |
| `lib/core/services/scheduler_service.dart` | `_scheduleBell` / `cancelAllBells` use `attend/bells` channel instead of `_plugin.zonedSchedule()` |

The `flutter_local_notifications` plugin is still used for the **timer notification** and **daily gatha** (those work fine). Only bell scheduling is now native.

**Status:** ✅ Fixed and verified on Samsung S25, Android 16.

---

## Key File Locations

| File | Role |
|------|------|
| `lib/core/services/notification_service.dart` | Channel creation, immediate bell, timer notification |
| `lib/core/services/scheduler_service.dart` | `zonedSchedule`, bell scheduling, `_scheduleBell` |
| `android/app/src/main/kotlin/.../MainActivity.kt` | `clearScheduledCache` MethodChannel |
| `android/app/src/main/res/raw/` | Audio files for notification channels |
| `lib/core/models/sound_option.dart` | `androidRawName` mapping (must match filenames in `res/raw/`) |

---

## flutter_local_notifications Internals (v18.0.1)

- **Scheduled notification storage:** SharedPreferences file `"scheduled_notifications"`, key `"scheduled_notifications"`
- **Receiver class:** `com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver`
- **Receiver log tag:** `"ScheduledNotifReceiver"` (NOT `"dexterous"`)
- **Flow:** `zonedSchedule` → saves JSON to SharedPrefs + creates PendingIntent with JSON in extras → AlarmManager fires → `ScheduledNotificationReceiver.onReceive` → Gson deserializes JSON from Intent extras → `FlutterLocalNotificationsPlugin.showNotification` → `NotificationManagerCompat.notify`
- **No try-catch in `onReceive`** — Gson failure or `notify()` exception will crash the receiver process and be logged as `FATAL EXCEPTION` or `BroadcastQueue` error
