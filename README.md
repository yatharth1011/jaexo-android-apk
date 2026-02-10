# JAEXO ULTIMATE - Flutter Edition

**Native Android study tracker with multi-device Wi-Fi synchronization**

## Overview

JAEXO ULTIMATE is a comprehensive study tracking and task management application specifically designed for JEE preparation. This Flutter version replaces the original Flask+ADB architecture with native Android functionality and real-time multi-device synchronization over local Wi-Fi networks.

### Key Features

- **Multi-Device Sync**: Automatic discovery and real-time synchronization between devices on the same Wi-Fi network
- **Profile System**: Network-tied profiles protected by custom 9-dot pattern locks
- **Native Music Control**: Direct Android intent integration for YouTube Music / ReVanced (no ADB required)
- **Intelligent Task Generation**: Hard-coded 2026 JEE schedule with automatic daily task creation
- **Multiple Study Modes**: Focus, Training (+4/-1/0 scoring), Online Test, and Offline tracking
- **Battery Intelligence**: Advanced battery drain estimation and remaining time calculation
- **Coin & Trophy System**: Earn coins for study time, accuracy, and target achievement
- **Themes**: 5 visual themes (Matrix, Redline, Deepspace, Amber, **Ghost** [default])

## Architecture Changes from Original

### Removed
- Flask backend server
- ADB device connection requirement
- Termux/shell script dependencies
- 16-second music loading animation

### Added
- Supabase real-time sync engine
- Native Android intents for music control
- Local network device discovery via mDNS
- Profile import/export for manual backup
- Music Anchor system for distributed playback

## Building the APK

### Option 1: GitHub Actions (Recommended)

1. Fork this repository
2. Ensure GitHub Actions is enabled in your repository settings
3. Push to `main` branch or manually trigger the workflow
4. Download the APK from the Actions artifacts tab

### Option 2: Local Build (Requires Flutter SDK)

```bash
cd jaexo_flutter
flutter pub get
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## Installation

1. **Download APK**: Get the APK from GitHub Actions artifacts or build locally
2. **Enable Unknown Sources**: Settings → Security → Allow installation from unknown sources
3. **Install**: Open the APK file and confirm installation
4. **Permissions**: Grant all requested permissions (Wi-Fi, Battery, Vibration, etc.)

## First-Time Setup

### Creating Your First Profile

1. **Connect to Wi-Fi**: Ensure you're connected to your home/study Wi-Fi network
2. **Launch App**: Open JAEXO ULTIMATE
3. **Create Profile**: Tap "CREATE NEW PROFILE"
4. **Set Pattern Lock**: Draw a pattern with at least 4 dots
5. **Confirm Pattern**: Redraw the same pattern to confirm

### Profile Behavior

- **Profiles are tied to specific Wi-Fi networks** (identified by SSID + BSSID)
- Switching Wi-Fi networks will prompt you to create a new profile or join an existing one
- All data syncs automatically between devices using the same profile on the same network
- Pattern lock is required to join an existing profile

## How Multi-Device Sync Works

### Device Discovery

1. All devices on the same Wi-Fi network broadcast their presence
2. Devices using the same profile ID automatically sync data
3. Changes propagate in real-time (tasks, logs, stats, music queue)
4. Offline changes merge when devices reconnect

### Music Anchor System

- **One device per profile** acts as the Music Anchor
- Only the Music Anchor performs actual playback
- Other devices send play/queue requests to the anchor
- Track info and artwork sync to all devices
- Switch the anchor from Command Deck → Music Anchor Selector

## Daily Usage

### Navigation

- **Space**: Toggle Command Deck
- **←/→**: Change date
- **A**: Add new task
- **Tap Date**: Jump to today

### Task Modes

1. **Offline**: Manual completion tracking (50 coins)
2. **Focus**: Timed study session (1 coin/minute)
3. **Training**: Question-based practice (+4/-1/0 scoring)
4. **Online Test**: Full test with manual mark entry

### Study Modes Detail

#### Training Mode
- Configure question count (default: 15)
- **CORRECT (+4)**: Advances to next question, adds 4 points
- **RETRY (-1)**: Stays on question, deducts 1 point
- **SKIP (0)**: Advances to next question, no points

#### Focus Mode
- Simple timer tracking
- Earn 1 coin per minute
- Pause/resume support

#### Online Test Mode
- Timer only
- Enter marks manually at completion

### Pausing Tasks

- Use **TAKE BREAK (SAVE)** during any active session
- Yellow banner appears on home screen with elapsed time
- Tap **RESUME** to continue from where you left off
- All progress (time, question number, score) is preserved

## Coin System

| Activity | Coins Earned |
|----------|--------------|
| Focus Mode | 1 coin/minute |
| Training Question | +4 correct, -1 retry, 0 skip |
| Online Test | Marks scored |
| Offline Task | 50 coins |
| Daily Target Met | 500 BONUS 🏆 |

## Command Deck Features

Access via Space key or `[COMMAND DECK]` link

- **Date Navigation**: PREV / NEXT buttons
- **Theme Selector**: 5 color themes
- **Music Search**: Direct YouTube Music search + Queue add
- **Music Controls**: PREV / P/P / NEXT
- **Reset Day**: Wipe logs and tasks for current date
- **Music Anchor**: Switch playback device

## Battery System

- **Charging**: Shows percentage with ⚡ icon
- **Discharging**: Shows estimated time until 20% battery
- **Low Power**: Alert when < 30 minutes remaining
- **Target Reached**: Warning when battery hits 20%
- **Battery Bar**: Thin green bar at top fills with charge level

## Data Management

### Export Profile

1. Open Command Deck
2. Tap "Export Profile"
3. JSON file saved to Downloads
4. Transfer manually to other devices

### Import Profile

1. Open Command Deck
2. Tap "Import Profile"
3. Select JSON file
4. Enter pattern lock

## Schedule System

The app includes a hard-coded 2026 schedule covering:

- **February**: Star Score-II tests, Board Prep, CBSE Board Exams
- **March**: Intensive testing phase, JEE Main prep
- **April**: PYQ (Previous Year Questions) mode
- **May 17, 2026**: JEE Advanced Examination Day

Tasks auto-generate based on the schedule event type:
- **TEST**: Paper attempt + analysis tasks
- **BOARD_PREP**: Subject-specific board prep
- **GRIND**: All subjects (Math, Physics, Chemistry breakdown)
- **HEAVY**: Test day with minimal study target

## Themes

Press Space → Theme dots to switch:

- **Matrix** (Green): Classic terminal aesthetic
- **Redline** (Red): High-alert focus mode
- **Deepspace** (Cyan): Cool space theme
- **Amber** (Yellow): Warm study ambiance
- **Ghost** (White): Default clean professional look

## Troubleshooting

### Music Not Playing

1. Ensure YouTube Music/ReVanced is installed
2. Check that the device is set as Music Anchor
3. Try playing a song directly in YouTube Music first
4. Check app permissions

### Sync Not Working

1. Verify all devices are on the **same Wi-Fi network**
2. Ensure the **same profile** is loaded on all devices
3. Check internet connectivity (required for Supabase sync)
4. Restart the app

### Battery Estimation Shows "SYNC..."

- Requires 2+ minutes of battery history
- Let the app run for a few minutes
- Estimation improves over time

### Pattern Lock Forgotten

- No recovery mechanism (security by design)
- Export profile regularly as backup
- Create new profile if locked out

## Supabase Configuration

This app requires a Supabase project for real-time sync. You need to provide:

```bash
# Build-time environment variables
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Or configure in GitHub Actions secrets:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

### Setting Up Supabase

1. Create a free Supabase project at https://supabase.com
2. No database tables needed (app uses Realtime Channels only)
3. Copy your project URL and anon key
4. Add to build command or GitHub secrets

## Permissions Required

- **Internet**: Supabase sync, artwork fetching
- **Wi-Fi State**: Network detection
- **Wake Lock**: Keep screen on during study sessions
- **Vibration**: Haptic feedback
- **Battery**: Drain estimation
- **Location** (coarse): Wi-Fi SSID access (Android requirement)

## Technical Stack

- **Framework**: Flutter 3.24.0
- **Backend**: Supabase (Realtime Channels & Presence)
- **Music**: Android Intents (`android.media.action.MEDIA_PLAY_FROM_SEARCH`)
- **Storage**: SharedPreferences + Supabase sync
- **State**: Provider pattern

## Contributing

This is a specialized app for a specific use case. If you want to modify:

1. Fork the repository
2. Modify `lib/data/schedule_2026.dart` for your own schedule
3. Adjust task generation logic in `lib/utils/task_generator.dart`
4. Rebuild and deploy

## Credits

Original Flask version by the JAEXO team. Flutter port maintains exact feature parity with native Android enhancements.

## License

Private use only. Not for distribution or commercial use.

---

**Built for JEE 2026 preparation. Study hard, track smart, achieve excellence.** 🎯
