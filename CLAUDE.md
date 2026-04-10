# CLAUDE.md — Attend

Meditation aid app for Android. Flutter, feature-first architecture.

@docs/flutter-expert.md

## Commands

```bash
flutter pub get          # install dependencies
flutter analyze lib/     # lint (must be clean before commits)
flutter run              # run on connected device/emulator
flutter build apk        # release build
```

## Architecture

**State:** vanilla Riverpod 2.x — `NotifierProvider`, `Provider`. No `@riverpod` annotations.  
**Nav:** GoRouter 14, ShellRoute → 4-tab bottom nav (Home / Timer / Library / Settings).  
**Persistence:** Hive (session history) + SharedPreferences (settings, flags).  
**Audio:** just_audio + audio_session.  
**Notifications:** flutter_local_notifications + workmanager.

## Critical constraint

`riverpod_generator` and `hive_generator` are **not** in pubspec — they conflict with the Dart SDK's analyzer version. All `.g.dart` files are hand-written. Do not add them back.

## Folder layout

```
lib/
├── main.dart                        # Hive init, SharedPrefs, AudioService, ProviderScope
├── app.dart                         # MaterialApp.router, light/dark themes
├── core/
│   ├── constants/                   # AppColors, AppTextStyles, AppDurations
│   ├── models/                      # TimerSession, NotificationConfig, Gatha, SoundOption
│   ├── providers/repositories.dart  # sharedPreferencesProvider, settingsRepo, sessionRepo
│   ├── repositories/                # SessionRepository (Hive), SettingsRepository (SharedPrefs)
│   ├── router/app_router.dart       # GoRouter + _AppShell (bottom nav)
│   ├── services/audio_service.dart  # AudioService singleton
│   └── utils/                       # DurationFormatter, date_utils
└── features/
    ├── home/views/home_screen.dart
    ├── timer/
    │   ├── providers/               # TimerState, TimerNotifier (timerProvider)
    │   ├── views/                   # TimerScreen, SessionHistoryScreen
    │   └── widgets/                 # TimerDial, DurationPicker, IntervalPicker
    ├── notifications/               # Phase 2 — NotificationSettingsScreen
    ├── gathas/                      # Phase 3 — GathaLibraryScreen, GathaDetailScreen
    └── settings/views/settings_screen.dart
```

## Themes

Light: bg `#F7F4EF` (cream), primary `#4A7C6F` (sage), secondary `#C8956C` (terracotta).  
Dark: bg `#1A1F2E`, primary `#7BAAA0` (teal), surface `#252B3B`.  
Always use `Theme.of(context).colorScheme.*` — never hardcode hex values in widgets.

## Phase status

- **Phase 1** ✅ Timer, session history, app shell, navigation
- **Phase 2** ✅ Mindfulness bell notifications
- **Phase 3** ✅ Gatha library (70 verses, favorites, daily rotation, search)
- **Phase 4** ✅ Polish, onboarding — complete
  - ✅ Onboarding screen (3-page PageView, permission + battery opt requests)
  - ✅ Router redirects first-time users to `/onboarding` via `routerProvider`
  - ✅ Timer sound picker in Settings (wired to `timerSoundId` pref)
  - ✅ Battery optimization exemption called on bell enable toggle
  - ✅ Session completion overlay — animated card (scale+fade+elastic check), replaces AlertDialog
  - ✅ Animated transitions — AnimatedSwitcher (fade+slide) on idle↔active controls; pause/play icon crossfade
  - ✅ Dial ring color — TweenAnimationBuilder<Color?> animates to secondary tint when paused
  - ✅ App icon — flutter_launcher_icons, adaptive icon (cream #F7F4EF bg + buddha foreground with 16% inset)

## Sound assets

Five `.ogg` files in `assets/audio/`: `bell_tibetan`, `bowl_singing`, `chime_soft`, `chime_crystal`, `nature_rain`.  
Mirrored in `android/app/src/main/res/raw/` for notification channels.

## Android notification strategy

- Channel per sound ID (`mindfulness_bell_<soundId>`) — sound is immutable after creation.
- Mindfulness bells: `autoCancel: true`, immediate programmatic cancel → sound-only, no shade entry.
- WorkManager daily scheduler + AlarmManager exact alarms for random bell times.
- `BootReceiver` re-enqueues the daily scheduler after reboot.

## Background & battery constraints (must not regress)

The app must be **completely dormant between notifications** — no persistent process, no held wake lock, no background isolate.

Rules to follow in every phase:
- **No foreground service** for the notification system. Foreground services require a permanent visible notification — wrong tool here.
- **No persistent audio session.** `just_audio` / `audio_session` must be released immediately after a bell fires. Never hold `AudioFocus` between bells.
- **AlarmManager must use `setExactAndAllowWhileIdle`** so bells fire during Doze mode without keeping the CPU awake the rest of the time. (`androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle` — already in `SchedulerService`.)
- **WorkManager task is daily-only** (reschedule next day's alarms). Never a short-interval periodic keep-alive.
- **WakeLock only during active timer sessions** (`wakelock_plus`). Release on pause/stop. Never held in the background.
- **Battery optimization exemption — use `PermissionService.requestBatteryOptimizationExemption()`** during onboarding when the user first enables bells. This prevents aggressive OEMs (Xiaomi, Samsung) from killing scheduled alarms, without needing a foreground service. MethodChannel `attend/battery` bridges to Android `PowerManager`. Check `isBatteryOptimizationIgnored()` first — only prompt if not already exempt.
- When adding new features: if something seems to require an always-on service, stop and reconsider first.
