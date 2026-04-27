# Attend

**Be here. Be now.**

A minimal meditation timer and mindfulness companion for Android. Attend combines a flexible session timer, scheduled mindfulness bells, and a library of 289 wisdom poems (gathas) from Buddhist, Stoic, Taoist, Confucian, and Hindu traditions.

![Version](https://img.shields.io/badge/version-1.0.4-blue)
![Platform](https://img.shields.io/badge/platform-Android-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

---

## Features

**Meditation Timer**
- Set any session duration with quick-select chips
- Pause and resume mid-session
- Optional interval bells every 5, 10, or 15 minutes
- Customizable completion and bell sounds
- Session history with elapsed times

**Mindfulness Bells**
- Gentle notifications throughout the day to return to the present
- Fully configurable schedule — days, time range, frequency
- Reliable delivery via native Android alarm scheduling

**Gatha Library**
- 289 wisdom poems across five traditions
- Daily featured poem on the home screen
- Search, browse, and save favorites
- Copy any poem to clipboard

**Simple Setup**
- Three-step onboarding — permissions, schedule, done
- No account required, no data leaves the device

---

## Wisdom Traditions

| Tradition | Texts |
|---|---|
| Buddhist | Dhammapada · Therigatha · Sutta Nipata (Metta, Mangala, Rhino Suttas) |
| Stoic | Marcus Aurelius Meditations · Epictetus · Seneca Letters to Lucilius |
| Taoist | Tao Te Ching · Zhuangzi |
| Confucian | Confucian Analects |
| Hindu | Bhagavad Gita (The Song Celestial) |

All texts are pre-1928 public domain translations or CC0-licensed.

---

## Download

Get the latest APK from [Releases](https://github.com/Natboa/Attend-Meditation-Aid/releases).

---

## Building from Source

**Requirements:** Flutter 3.x, Android SDK

```bash
git clone https://github.com/Natboa/Attend-Meditation-Aid.git
cd Attend-Meditation-Aid
flutter pub get
flutter run
```

**Release APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Tech Stack

| Concern | Library |
|---|---|
| State management | flutter_riverpod |
| Navigation | go_router |
| Persistence | shared_preferences |
| Audio | just_audio |
| Notifications | flutter_local_notifications |
| Background scheduling | Native Android AlarmManager |
| Typography | google_fonts |

---

## License

MIT
