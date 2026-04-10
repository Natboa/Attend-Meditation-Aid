# Attend — Meditation Aid App: Implementation Plan

## Context

Building "Attend" — a Flutter Android meditation aid app — from an empty project directory. The app name reflects its philosophy: attend to the present moment. Core features are a meditation timer with interval bells, mindfulness bell notifications scheduled randomly throughout the day, a Gatha (mindfulness poem) library with poem of the day, and beautiful UI with animations and light/dark theming. All data is local-only. No cloud sync.

---

## User Stories

### Meditation Timer
- Set a meditation duration (pre-set or custom) and start a countdown timer
- Hear a bell at the start of the session
- Hear interval bells at a chosen interval (e.g., every 5, 10, or 15 minutes)
- Hear a bell at the end of the session
- Timer keeps running when the screen is locked
- View session history (date, duration, completed/stopped)

### Mindfulness Bell Notifications
- Receive random bell reminders throughout the day as "be present" moments
- Configure: which days of the week, start/end hours, and how many bells per day
- Delivered as sound-only: a bell plays and the notification auto-cancels immediately — no banner, no text, no persistent entry in the shade
- Choose a bell sound independently from a curated set

### Sound Selection
- Each feature has its own independent sound picker: one for the meditation timer (bells + intervals), one for mindfulness notifications
- Preview each available sound before selecting
- Timer sound: applies to session start bell, interval bells, and session end bell
- Mindfulness sound: applies to the background bell that fires during the day

### Gatha Library
- Browse a library of 80+ mindfulness poems (gathas), searchable by keyword and filterable by tag
- Favourite gathas and access them in a favourites view
- See one poem of the day on the home screen (changes daily, deterministic)
- Optional: receive the daily gatha as a morning notification at a set time
- All content works offline (bundled JSON)

### UI / UX
- Follows system light/dark theme automatically
- Smooth, calm animations — timer pulse, page transitions, card reveals
- Elegant typography (serif for poems, sans for UI)

---

## Tech Stack

```yaml
dependencies:
  flutter_riverpod: ^2.6.1        # state management
  riverpod_annotation: ^2.6.1
  go_router: ^14.6.2              # navigation with deep links
  hive_flutter: ^1.1.0            # local persistence for sessions
  shared_preferences: ^2.3.3      # settings and flags
  just_audio: ^0.9.42             # audio playback
  audio_session: ^0.1.21          # Android audio focus
  flutter_local_notifications: ^18.0.1
  workmanager: ^0.5.2             # background scheduling
  google_fonts: ^6.2.1
  wakelock_plus: ^1.2.8           # keep CPU alive during timer
  share_plus: ^10.0.3             # share gathas
  intl: ^0.19.0
  uuid: ^4.5.1

dev_dependencies:
  riverpod_generator: ^2.6.1
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
  mockito: ^5.4.4
  flutter_lints: ^5.0.0
```

**Key decisions:**
- Riverpod (not Provider) — compile-safe, no BuildContext dependency, better for async state and isolates
- Hive (not SQLite) — typed, zero-boilerplate object store; adequate for session history at this scale
- WorkManager + AlarmManager hybrid — WorkManager for daily rescheduling (survives reboots), AlarmManager for exact random times within each day
- just_audio over audioplayers — better Android audio focus, more actively maintained

---

## Folder Architecture (Feature-First)

```
lib/
├── main.dart                        # ProviderScope, Hive init, runApp
├── app.dart                         # MaterialApp with theme + GoRouter
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # light/dark palettes (sage, cream, slate)
│   │   ├── app_text_styles.dart     # Lora (serif) + Nunito (sans)
│   │   └── app_durations.dart       # animation timing constants
│   ├── models/
│   │   ├── timer_session.dart       # Hive object: id, startedAt, duration, completed, soundId
│   │   ├── notification_config.dart # Hive object: enabled, activeDays, hours, frequency, soundId
│   │   ├── gatha.dart               # id, title, body, attribution, tags, isFavourite
│   │   └── sound_option.dart        # id, displayName, assetPath, androidRawName
│   ├── services/
│   │   ├── audio_service.dart       # just_audio wrapper: playBell, previewSound, stop
│   │   ├── notification_service.dart # channel management + show/cancel
│   │   ├── scheduler_service.dart   # random bell scheduling logic
│   │   └── permission_service.dart  # runtime permission requests
│   ├── repositories/
│   │   ├── session_repository.dart  # Hive CRUD for TimerSession
│   │   ├── settings_repository.dart # SharedPreferences wrapper
│   │   └── gatha_repository.dart    # JSON loader + favourites
│   ├── router/
│   │   └── app_router.dart          # GoRouter: shell route + named routes
│   └── utils/
│       ├── date_utils.dart
│       └── duration_formatter.dart
├── features/
│   ├── home/
│   │   └── views/home_screen.dart   # poem-of-day card + quick-start button
│   ├── timer/
│   │   ├── providers/timer_provider.dart
│   │   ├── views/timer_screen.dart
│   │   ├── views/session_history_screen.dart
│   │   └── widgets/                 # timer_dial.dart, duration_picker.dart, interval_picker.dart
│   ├── notifications/
│   │   ├── providers/notification_config_provider.dart
│   │   ├── views/notification_settings_screen.dart
│   │   └── widgets/                 # day_selector.dart, hour_range_slider.dart, frequency_picker.dart
│   ├── gathas/
│   │   ├── providers/gatha_provider.dart
│   │   ├── views/gatha_library_screen.dart
│   │   ├── views/gatha_detail_screen.dart
│   │   └── widgets/                 # gatha_card.dart, poem_of_day_card.dart
│   └── settings/
│       ├── providers/settings_provider.dart
│       ├── views/settings_screen.dart
│       └── widgets/sound_preview_tile.dart
assets/
├── audio/                           # bell_tibetan.ogg, bowl_singing.ogg, chime_soft.ogg,
│                                    # chime_crystal.ogg, nature_rain.ogg (5 sounds)
└── data/
    └── gathas.json                  # 80+ pre-bundled gathas
android/app/src/main/
├── AndroidManifest.xml              # permissions, receivers, foreground service
├── res/raw/                         # same audio files for notification channels
└── kotlin/.../
    ├── MainActivity.kt
    ├── AttendApplication.kt         # WorkManager initializer
    └── BootReceiver.kt              # re-register scheduler on reboot
```

---

## Data Models

### TimerSession (Hive, typeId: 0)
```dart
String id                  // UUID
DateTime startedAt
Duration duration           // actual elapsed
Duration? target            // null = open-ended
bool completed              // false = user stopped early
String soundId              // which bell was used
Duration? intervalDuration  // null = no interval bells
```

### NotificationConfig (Hive, typeId: 1)
```dart
bool enabled
List<int> activeDays        // 1=Mon..7=Sun (ISO weekday)
int startHour               // 0–23
int endHour                 // 0–23
int frequencyPerDay         // 1–10
String bellSoundId          // sound for mindfulness bells (independent of timer sound)
bool dailyGathaEnabled      // send morning gatha notification
int dailyGathaHour          // default 7
```

### AppSettings (SharedPreferences)
```dart
String timerSoundId         // sound for timer start/interval/end bells
// stored as plain string key, not Hive — accessed from both main isolate and background
```

### Gatha (in-memory from JSON, favourites in SharedPreferences)
```dart
String id
String title
String body                 // full multiline poem
String? attribution
List<String> tags
bool isFavourite            // derived from SharedPreferences Set<String>
```

### gathas.json structure
```json
{
  "version": 1,
  "gathas": [
    {
      "id": "g001",
      "title": "Breathing In",
      "body": "Breathing in, I calm my body.\nBreathing out, I smile.\nDwelling in the present moment,\nI know this is a wonderful moment.",
      "attribution": "Thich Nhat Hanh",
      "tags": ["breathing", "present moment"]
    }
  ]
}
```

---

## Android Permissions & Channels

### AndroidManifest.xml permissions
```xml
RECEIVE_BOOT_COMPLETED
SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM
POST_NOTIFICATIONS
FOREGROUND_SERVICE + FOREGROUND_SERVICE_MEDIA_PLAYBACK
WAKE_LOCK
```

### Notification channels

| Channel ID | Purpose | Sound |
|---|---|---|
| `meditation_timer` | Foreground service notification while timer runs | silent |
| `mindfulness_bell_<soundId>` | Mindfulness bell reminders (one per sound) | custom bell |
| `daily_gatha` | Morning poem notification | none |

**Sound-per-channel strategy**: Android does not allow modifying a channel's sound after creation. When the user changes their mindfulness bell sound, a new channel is created (`mindfulness_bell_<newSoundId>`) and the old one is retired. All pending alarms are rescheduled to target the new channel.

**Auto-cancel / sound-only delivery**: Mindfulness bell notifications are posted with `autoCancel: true`, `ongoing: false`, `importance: HIGH` (so the sound plays), and `styleInformation: null` (no body text). The notification is immediately cancelled programmatically after posting — the user hears the bell but sees no banner and no shade entry. If the app is in the foreground when the alarm fires, the sound is played directly via `AudioService` and no notification is posted at all.

---

## Scheduling Architecture

**Problem**: Notifications must fire at N random times within a user-defined time window on specific days of the week.

**Solution** (WorkManager + AlarmManager hybrid):

1. A `OneTimeWorkRequest` ("daily scheduler") fires once per day at midnight (or at app open if today's bells haven't been scheduled yet).
2. It computes N random `DateTime` values within `[startHour, endHour]` for today, if today is an active day.
3. Each computed time is registered via `android_alarm_manager_plus` with `setExactAndAllowWhileIdle()`.
4. At the end of the task, it schedules the next daily task for the following eligible day.
5. `BootReceiver.kt` re-enqueues the daily task after device reboot.

---

## Phased Rollout

---

### Phase 1 — Project Setup + Core Timer + UI Shell

**Deliverable**: A working meditation timer with interval bells, session history, and the full app navigation skeleton.

**Tasks:**
1. `flutter create attend --org com.attend --platforms android`; set `minSdkVersion 26`, `targetSdkVersion 35`
2. Add all pubspec.yaml dependencies; register audio assets and gathas.json
3. `AppColors`, `AppTextStyles` (Lora + Nunito), `AppDurations`
4. `app.dart`: `MaterialApp` with `ThemeMode.system`, light/dark `ColorScheme`, Material 3 bottom nav (4 tabs: Home, Timer, Library, Settings)
5. `app_router.dart`: GoRouter shell route + all named routes
6. Hive init in `main.dart`; register `TimerSession` adapter
7. `TimerSession` model + `SessionRepository` (save, getAll, delete)
8. `AudioService`: `playBell(soundId)`, `previewSound(soundId)`, `stop()`
9. `TimerNotifier`: states (idle/running/paused/finished), `start(target, intervalDuration)`, `pause()`, `resume()`, `stop()`
   - `Timer.periodic` at 100ms for elapsed tracking
   - Plays bell on start, at each interval, and at finish
   - Acquires WakeLock on start, releases on finish/stop
   - Starts Android foreground service notification on start
   - Saves `TimerSession` to Hive on finish/stop
10. `TimerScreen`: animated circular dial (`CustomPainter`), large time display, duration picker (5/10/15/20/30/45/60 min + custom), interval picker (off/5/10/15 min), play/pause/stop FABs
11. `SessionHistoryScreen`: `ListView` of session tiles, swipe-to-delete
12. `HomeScreen`: placeholder poem card + quick-start button (last used duration)

**Verification:**
- Timer counts down accurately; screen-lock test shows timer still running in history after unlock
- Interval bells fire at correct times
- Bell plays at start and end
- Session saved to history on completion and early stop
- All 4 nav tabs reachable; dark/light mode follows system

---

### Phase 2 — Mindfulness Bell Notification System

**Deliverable**: Reliable random notification scheduling with full user configuration.

**Tasks:**
1. `PermissionService`: request `POST_NOTIFICATIONS` (Android 13+), guide user to grant `SCHEDULE_EXACT_ALARM`, prompt battery optimization exemption
2. `NotificationService`: init `FlutterLocalNotificationsPlugin`, create all channels, `showMindfulnessBell(body, soundId)`, `cancelAll()`
3. `scheduler_service.dart`: `computeRandomTimes(config, date)` → `List<DateTime>`, `scheduleDailyBells(config)`, `cancelAllBells()`, `rescheduleForTomorrow(config)`
4. WorkManager background task (Dart isolate entry point): loads config from SharedPreferences, calls `scheduleDailyBells`, re-enqueues self for next active day
5. `BootReceiver.kt`: `BOOT_COMPLETED` → enqueue WorkManager daily task
6. `NotificationConfig` model + persistence in `SettingsRepository`
7. `NotificationConfigNotifier`: `updateDays`, `updateHourRange`, `updateFrequency`, `setEnabled` — each triggers reschedule
8. `NotificationSettingsScreen`:
   - Master on/off toggle
   - `DaySelectorWidget` (7 toggle chips, Mon–Sun)
   - `HourRangeSlider` (RangeSlider 0–23, formatted as "9:00 AM – 6:00 PM")
   - `FrequencyPicker` (1–10 per day)
   - Sound selector (placeholder, wired in Phase 4)
   - Live preview of next scheduled times

**Verification:**
- Configure Mon–Fri, 10am–5pm, 5x/day; verify 5 alarms in `adb shell dumpsys alarm`
- Notifications arrive within the configured window
- Reboot device; verify notifications resume
- Android 13+ permission prompt shown on first enable
- Disable toggle; verify no further notifications

---

### Phase 3 — Gatha Library + Poem of the Day

**Deliverable**: Full gatha browsing, favourites, poem of the day on home screen, optional morning notification.

**Tasks:**
1. Author 80+ gathas in `assets/data/gathas.json` across categories: breathing, walking, eating, morning, evening, gratitude, impermanence, compassion, present moment
2. `GathaRepository`: `loadAll()` (parse JSON once, cache in memory), `getPoemOfDay()` (`dayOfYear % total` — deterministic), `toggleFavourite(id)`, `getFavouriteIds()`
3. `GathaProvider`: `allGathasProvider` (FutureProvider), `filteredGathasProvider(tag, query)` (derived), `poemOfDayProvider` (Provider), `favouriteGathasProvider`
4. `GathaLibraryScreen`: `SliverAppBar` + search field, tag filter chips, `SliverList` of `GathaCard` (title, first 2 lines, favourite heart)
5. `GathaDetailScreen`: full poem in large Lora serif, attribution, favourite toggle, share button (`share_plus`)
6. `PoemOfDayCard` on home screen: poem title + first stanza + "Read more" → `GathaDetailScreen`; refreshes at midnight
7. Daily gatha notification: `WorkManager` `OneTimeWorkRequest` at user-set hour; notification body = first 2 lines; tap deep-links to gatha detail via GoRouter

**Verification:**
- All 80+ gathas render without overflow
- Poem of day changes at midnight (test by forwarding device date)
- Favourite persists across restarts
- Tag filter + search work correctly
- Deep link from daily notification opens correct gatha

---

### Phase 4 — Polish, Animations, Sound Selection, Onboarding

**Deliverable**: Production-ready app with complete sound selection, smooth animations, onboarding, and accessibility pass.

**Tasks:**
1. **Sound selection UI** (`SoundPreviewTile`): two separate pickers — one in Timer settings (session bells), one in Notification settings (mindfulness bell). Each shows 5 sounds, tap to preview (3-second clip), checkmark on selected. Timer sound stored in SharedPreferences; mindfulness sound stored in `NotificationConfig`.
2. **Timer dial animation**: `CustomPainter` arc with `AnimationController`; subtle pulse effect on time display (scale 1.0→1.02→1.0, 4s cycle via `AnimatedBuilder`)
3. **Page transitions**: GoRouter custom transitions using `animations` package — `FadeThroughTransition` for bottom nav switches, `SharedAxisTransition` (horizontal) for drill-downs
4. **Onboarding** (3-page `PageView`, shown once on first launch):
   - Page 1: "Attend. Be here. Be now." + philosophy
   - Page 2: Timer intro with animated mock dial
   - Page 3: Notification permission request inline
   - Dot indicator + "Begin" button; skippable
5. **Theme refinement**:
   - Light: bg `#F7F4EF` (warm cream), primary `#4A7C6F` (sage), accent `#C8956C` (terracotta)
   - Dark: bg `#1A1F2E` (deep blue-grey), primary `#7BAAA0` (muted teal), surface `#252B3B`
   - Verify WCAG AA contrast ratios
6. **Haptic feedback**: `HapticFeedback.lightImpact()` on timer controls; medium impact on bell play
7. **Home screen enhancements**: streak counter (consecutive days with a session), weekly/monthly stats, animated greeting fade-in
8. **Empty states**: session history ("Your first sit awaits"), notification disabled prompt
9. **Accessibility**: `Semantics` on custom widgets, 48dp minimum touch targets, `textScaleFactor` support
10. **App icon + splash**: design bell/lotus icon, generate with `flutter_launcher_icons`, native splash with `flutter_native_splash`

**Verification:**
- Onboarding: first launch only; "Begin" sets `hasSeenOnboarding`
- All 5 sounds preview; changing sound creates new notification channel
- Timer pulse: profile mode, <16ms frame budget confirmed
- Page transitions at 60fps on mid-range device
- TalkBack navigation through all primary flows
- Layout integrity on 5" and 6.7" screens
- Battery saver + "Don't keep activities" + airplane mode tests

---

## Testing Strategy

### Unit tests
- `GathaRepository.getPoemOfDay()` — same poem within a day, different poem next day
- `SchedulerService.computeRandomTimes()` — returns exactly N times, all within window, only on active days
- `TimerSession` — Hive serialization round-trip
- `DurationFormatter` — edge cases (0s, 59s, 3600s)

### Widget tests
- `TimerDial` at 0%, 50%, 100% progress; golden test
- `DaySelectorWidget` toggle state
- `GathaCard` — truncated body, favourite state

### Integration tests
- Full timer flow: start → run to completion → verify session in history
- Notification schedule: set config → verify `scheduleDailyBells` called with correct params
- Gatha favouriting: favourite → restart → still favourited

### Manual QA
- Test on API 26 (minimum) and API 35 (target)
- "Don't keep activities" enabled in developer options
- Battery saver mode on
- Airplane mode (timer + local notifications still work)
- Aggressive OEM battery optimizer (e.g., Xiaomi MIUI)
- TalkBack active

---

## Risk Register

| Risk | Likelihood | Mitigation |
|---|---|---|
| OEM battery optimization kills background tasks | High | Request exemption in onboarding; document known OEM workarounds |
| `SCHEDULE_EXACT_ALARM` permission revoked at runtime | Medium | Check before each scheduling call; fall back to inexact alarm with user warning |
| Notification channel sound immutable after creation | Medium | Channel-per-sound strategy; retire old channels |
| `just_audio` audio focus conflict with media apps | Low | `audio_session` handles focus negotiation via `AudioSession.configure()` |
| Hive box corruption on force-kill | Low | `box.put()` is atomic; repository catches and reports errors |
