# RepForge

A native SwiftUI workout tracker: browse an 873-exercise library, log workouts with a
rest timer, build reusable routines, and review history/PRs with charts. Built to be
compiled without Xcode (via CI) and installed on your iPhone without an Apple
Developer Program membership.

This is an original app inspired by the *category* of workout trackers (Fitbod,
Strong, Hevy, etc.) — it is not affiliated with, and does not reuse any code,
copy, or media from, any of those apps. The exercise data comes from the
[free-exercise-db](https://github.com/yuhonas/free-exercise-db) dataset (public
domain / Unlicense).

## What's in v1 ("solid core")

- Exercise library: search + filter by body region and equipment, full instructions
- Workout logging: sets, reps, weight, warm-up sets, completion tracking, rest timer
  with a local notification (fires even if you background the app)
- Routine builder: reorderable custom routines, start a workout from one in one tap
- History: past sessions, per-exercise history, estimated 1RM trend chart, PRs
- Stats: workout streak, weekly volume chart, lb/kg toggle
- All data stored locally on-device (SwiftData) — no account, no server, no tracking

**Not yet built** (planned next, see Roadmap): AI-generated workout recommendations /
muscle-recovery modeling, Apple Watch app, Apple Health sync, progress photos &
body measurements, plate calculator, supersets, exercise photos/videos.

## Why the build process looks like this

iOS apps are normally compiled and signed with Xcode, which only runs on macOS —
and this was built from Windows with no Mac available. So instead:

- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** generates the `.xcodeproj` from
  [`project.yml`](project.yml) at build time, so no binary Xcode project file has to
  be hand-maintained.
- **GitHub Actions** (`.github/workflows/build-ipa.yml`) runs on a free macOS runner,
  builds the app with code signing turned off, and packages it into an *unsigned*
  `.ipa`. No Apple credentials are ever stored in this repo or in CI.
- **[Sideloadly](https://sideloadly.io/)** (Windows/macOS) takes that unsigned `.ipa`
  and signs + installs it using your own free Apple ID, directly over USB.

## One-time setup

1. **A free Apple ID** — your existing one works, or create a fresh one at
   [appleid.apple.com](https://appleid.apple.com) if you'd rather keep sideloading
   separate from your main account.
2. Generate an **app-specific password** for that Apple ID: appleid.apple.com →
   Sign-In and Security → App-Specific Passwords. Sideloadly needs this, not your
   real password.
3. Install **[Sideloadly](https://sideloadly.io/)** on your Windows PC.
4. Install **[Apple Devices](https://apps.microsoft.com/detail/9np83lwlpz9k)** (or
   iTunes) from the Microsoft Store so Windows can talk to your iPhone over USB.
5. Push this project to a GitHub repo (public or private, either works on the free
   tier):
   ```bash
   git remote add origin https://github.com/<you>/<repo>.git
   git push -u origin main
   ```

## Building the IPA

The workflow runs automatically on every push to `main`, or trigger it manually:
GitHub repo → **Actions** tab → **Build Unsigned IPA** → **Run workflow**.

It takes ~5–10 minutes. When it's green, open the run, and under **Artifacts**
download `RepForge-unsigned-ipa` — unzip it to get `RepForge.ipa`.

## Installing on your iPhone

1. Plug your iPhone into the PC, unlock it, and tap **Trust** on the prompt.
2. Open Sideloadly, drag `RepForge.ipa` into it.
3. Enter your Apple ID and the app-specific password from setup step 2.
4. Click **Start**. Sideloadly signs the app with a free personal certificate and
   installs it.
5. On the iPhone: **Settings → General → VPN & Device Management** → tap your
   Apple ID under "Developer App" → **Trust**.
6. Launch RepForge from the home screen.

### The 7-day catch

Apps signed with a **free** (non-paid) Apple ID expire after 7 days — iOS will
refuse to open it until you re-sign. Two ways to handle it:

- **Manual**: repeat the Sideloadly steps above once a week. As long as you
  re-install before the old signature expires, it's treated as an update and your
  workout history is preserved. If it already expired and you had to delete the app
  first, local data is lost — so try not to let it lapse.
- **Automatic-ish**: install [AltStore](https://altstore.io) instead of/alongside
  Sideloadly and enable its background refresh — as long as your PC and phone are
  on the same Wi-Fi periodically, it re-signs for you.

A free Apple ID can also only have **3 apps** sideloaded at once and up to **10 app
IDs registered per 7 days** — rarely an issue for personal use, but worth knowing.

## Customizing

- Change the bundle identifier in [`project.yml`](project.yml)
  (`PRODUCT_BUNDLE_IDENTIFIER: com.repforge.app`) to something like
  `com.yourname.repforge` if you want it distinctly yours.
- Swap the placeholder app icon at
  `Sources/RepForge/Assets.xcassets/AppIcon.appiconset/icon-1024.png` for your own
  1024×1024 PNG.
- Default rest time is 90s (`ExerciseLogSection.swift`, `defaultRestSeconds`) —
  a settings screen to change this in-app is a good first thing to add yourself.

## Roadmap (phase 2+)

Roughly in order of value toward Fitbod parity:
1. Settings screen (rest time, warm-up defaults, plate calculator)
2. Superset / circuit support in the active workout view
3. Muscle-recovery-aware workout generation (a real differentiator — needs a
   fatigue model per muscle group based on recent volume/intensity)
4. Apple HealthKit sync (active energy, workout entries)
5. Apple Watch companion app (start/log sets from the wrist)
6. Progress photos & body measurements
7. Exercise demo images (the free-exercise-db dataset has these too; omitted from
   v1 to keep the bundle small and the build simple)

## Project structure

```
project.yml                   XcodeGen spec (generates the .xcodeproj)
Sources/RepForge/
  App/                         App entry point, SwiftData container setup
  Models/                      Exercise (static) + SwiftData models (workouts, routines)
  Data/                        Bundled exercises.json + loader
  Views/                       SwiftUI screens, grouped by feature
  Utilities/                   Rest timer, unit conversion, active-workout state
.github/workflows/build-ipa.yml   CI build → unsigned .ipa
```
