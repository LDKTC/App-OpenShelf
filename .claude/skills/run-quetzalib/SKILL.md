---
name: run-quetzalib
description: Run, test, analyze, or verify the QuetzaLib Flutter/Android app (ISBN scan + personal library manager). Use when asked to run/start the app, take a screenshot, click through the UI, or verify a screen/service change works — and to know honestly what can and can't be checked in a given environment.
---

# Run QuetzaLib (Flutter Android app)

QuetzaLib is a Flutter app, Android-only target, built as an `.apk`. Unlike
DraconDex (an Electron desktop app with a Playwright `_electron` driver),
there is **no programmatic UI-driver script** in this repo — Flutter's
equivalent (`integration_test` + `flutter drive` against a real
device/emulator) isn't set up here yet. This skill documents the real ways to
run/verify the app and is honest about what each environment can actually do.

## Environment limits — check before claiming anything works

```bash
which flutter adb
flutter devices
```

- **No `flutter` on PATH** (true in this repo's default sandboxed session,
  per the README's "Notes on this environment"): you can still read code and
  reason about it, but cannot analyze, test, or build. Say so explicitly
  rather than claiming verification you didn't do.
- **`flutter` present, no device/emulator, no Android SDK reachable**
  (`dl.google.com` blocked, common in sandboxes): `flutter pub get`,
  `flutter analyze`, and `flutter test` all still work (they don't need a
  device) — this is the floor of what you can verify. `flutter build apk`
  and anything requiring an emulator will not.
- **`flutter` + Android SDK + emulator/device available**: the full human
  path below works, including `adb screenshot` for real visual verification.

Never claim "verified in the running app" when only `flutter analyze`/`flutter
test` actually ran — say "verified by static analysis and tests; not run on
device" instead. This mirrors the honesty the project's own README already
practices about this exact limitation.

## Prerequisites (when Flutter is available)

```bash
flutter pub get
```

## Static verification (works in any environment with Flutter on PATH)

```bash
flutter analyze     # static analysis — this repo keeps it at zero issues
flutter test         # unit + widget tests — see test/ layout below
```

`test/` layout, as a model for adding coverage to a change:
- `test/isbn_utils_test.dart` — ISBN-10/13 validation/normalization unit tests
- `test/stamp_test.dart` — reading-status stamp model tests
- `test/services/book_metadata_service_test.dart`,
  `test/services/ocr_service_test.dart`,
  `test/services/metadata_providers/` — service-layer tests, network calls
  mocked via `http`'s test client rather than hitting real APIs
- `test/widget_test.dart` — a widget test that pumps `HomeScreen` inside a
  `MaterialApp` with `AppLocalizations.delegate` and a fresh
  `LibraryProvider`, then asserts on rendered text (`find.text(...)`,
  `find.textContaining(...)`). This is the closest thing this repo has to a
  driver — extend it (or add siblings) to assert a screen renders/behaves as
  expected rather than trying to add a whole integration-test harness for a
  one-off check.

## Human path — run on a device/emulator

```bash
flutter run                       # opens on a connected device/emulator; hot-reload with 'r'
flutter build apk                 # release apk -> build/app/outputs/flutter-apk/app-release.apk
flutter build apk --debug
```

Requires the Android SDK (Android Studio is the easiest way to get it) and a
connected device or running emulator (`flutter devices` to confirm one is
visible).

## Screenshot / visual verification

With a device/emulator attached:

```bash
adb exec-out screencap -p > shot.png    # raw device screenshot
```

Read the resulting PNG with the Read tool before writing anything about what
it shows — don't infer visual state from code alone. There's no scripted
click/navigate layer here (unlike DraconDex's `driver.mjs` command
vocabulary) — navigate manually via `adb shell input tap <x> <y>` /
`adb shell input text <string>` if you need to reach a specific screen
before capturing, or drive it by hand if a human is present.

## CI equivalents (what actually verifies this app end-to-end today)

- `.github/workflows/build.yml` — runs on every push/PR: `flutter pub get`
  → `flutter analyze` → `flutter test` → `flutter build apk` (debug and
  release), uploaded as artifacts. This is the closest thing to a full
  smoke test this repo has, and runs in an environment where the Android SDK
  **is** reachable — if you can't build/run locally, this is where a change
  gets its first real build+test pass.
- `.github/workflows/release.yml` — see `.claude/skills/build-release-git/SKILL.md`.

## Gotchas

- **Default locale follows the device.** `AppLocalizations` supports `en`
  and `th` (`lib/l10n/app_localizations.dart`), with any key missing from a
  non-English table falling back to the English value rather than crashing —
  see `.claude/skills/quetzalib-l10n-style/SKILL.md` before adding
  user-facing strings.
- **Camera/scanner features (`mobile_scanner`, `google_mlkit_*`) need a real
  device or an emulator with camera support wired up** — they will not
  meaningfully exercise on a bare `flutter test` run; those code paths are
  the ones most likely to only get verified by CI's real build or a human on
  a physical device.
- **`flutter run` uses whatever local SQLite state already exists on the
  device** — there's no scratch-data-dir isolation flag like DraconDex's
  `DRACONDEX_DATA_DIR`. Use a fresh emulator/AVD, or clear app data
  (`adb shell pm clear com.<applicationId>`), if you need a clean-library
  starting state for a test.
- **The in-app updater (`update_service.dart`) hits the real GitHub Releases
  API** — don't rely on it in an offline/sandboxed run; treat its network
  calls as something to read in code rather than trigger live unless you
  intend to.

## Troubleshooting

- `flutter: command not found` → this environment doesn't have the Flutter
  SDK on PATH; fall back to static code reading, and say so.
- `No devices found` / `flutter run` hangs waiting for a device → no
  emulator running and no physical device attached; start one
  (`flutter emulators --launch <id>`) or attach a device with USB debugging
  enabled.
- `flutter build apk` fails fetching `dl.google.com` → this sandbox can't
  reach Google's Maven/SDK mirrors; this exact limitation is called out in
  this repo's own README under "Notes on this environment" — rely on CI
  (`build.yml`) for a real build in that case.
