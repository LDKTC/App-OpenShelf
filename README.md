# QuetzaLib

Android app (Flutter, built as an `.apk`) that scans the ISBN barcode on
the back of a book, looks up its metadata, and adds it to your personal
library, stored locally on-device in SQLite.

## Features

- **Scan-to-add**: scan an ISBN-10/13 barcode with the camera and look up
  the book automatically.
- **Metadata lookup**:
  - Books: [Google Books API](https://developers.google.com/books) first,
    falling back to [Open Library](https://openlibrary.org/dev/docs/api/books).
  - Light novels: [RanobeDB](https://ranobedb.org) is tried last as a
    specialized fallback. Its [public API](https://ranobedb.org/api/docs/v0)
    has no direct ISBN search, so this is best-effort — see the note in
    `ranobedb_provider.dart`.
- **Add by ISBN text entry**: type or paste an ISBN-10/13 instead of
  scanning, via the same lookup flow as the barcode scanner.
- **Manual add/edit**: for books with no barcode or no metadata match.
- **Search the shelf by scan**: scan a book already in your library to jump
  straight to it, in addition to the free-text search.
- **Cover/spine scanning**: scan a book's front cover, spine, and back
  cover into a reusable preset (a book can have several; one is active at
  a time) from the book detail screen, or promote its existing API
  thumbnail into a preset instead of rescanning it. Presets can be edited
  afterward — skip a slot now and scan it in later. Capture uses Google
  Play services' document scanner instead of a plain camera shot, so the
  page is auto-detected, straightened, and cropped before it's saved.
- **Scan-to-fill book fields**: a scan button next to Title, Authors,
  Illustrators, ISBN, and Publisher in the book editor photographs that
  text and runs OCR on it. The recognized text is always shown back to you
  in an editable review dialog first — nothing is written into the field
  until you approve it (editing it first if needed). See
  [OCR text scanning](#ocr-text-scanning) below for the on-device vs. Cloud
  Vision tradeoff.
- **Saved pages**: photograph a page or illustration inside a book and
  keep it as an in-app reminder, with an optional label and note.
- **Reading-status stamps**: a timeline of `reading` / `finished` /
  `dropped` / `paused` stamps per book instead of a single status field —
  add, edit, or delete a stamp at any time; a book's current status is
  just its most recent stamp.
- **Shelf view**: browse the library as a visual shelf of spines or covers
  (a global List/Shelf and spine/cover toggle), falling back to a text
  info tile for books with no scanned cover yet.
- **Library management**: categorize books (custom categories you define)
  and search/filter by title, author, ISBN, or reading-status stamp.
- **Fully local**: all data lives in an on-device SQLite database
  (via `sqflite`) — nothing is synced anywhere.
- **In-app updates**: since QuetzaLib isn't distributed through the Play
  Store, **Settings → App update** checks GitHub Releases for a newer
  build and installs it over the existing app — see [App updates](#app-updates)
  below.

## Tech stack

- Flutter (Android target only), Material 3
- `sqflite` for local storage
- `mobile_scanner` for barcode scanning + `permission_handler` for the
  camera permission
- `image_picker` for cover/spine/page photo capture, and the OCR-scan
  photo source in the book editor
- `google_mlkit_document_scanner` for cover/spine/back capture (auto edge
  detection, perspective correction, cropping)
- `google_mlkit_text_recognition` for on-device OCR (default; Latin script
  only), with an optional Cloud Vision API fallback for Thai text
- `provider` for state management
- `http` for metadata lookups (Google Books JSON, Open Library JSON) and
  the optional Cloud Vision OCR call
- `package_info_plus` + `path_provider` for the in-app updater (current
  version check, downloaded-APK staging)

## Project layout

```
lib/
  models/            Book, BookCategory, ReadingStamp, BookCoverPreset, BookPage,
                      BookMetadata, AppUpdateInfo
  services/
    database_service.dart       sqflite schema + CRUD
    isbn_utils.dart             ISBN validation/normalization
    settings_service.dart       persisted app settings (Cloud Vision API key,
                                 shelf display mode)
    book_metadata_service.dart  orchestrates provider lookup order
    book_lookup_service.dart    shared ISBN -> existing book/metadata/not-found resolution
    metadata_providers/         google_books, open_library, ranobedb
    document_scanner_service.dart  cover/spine/back capture via the ML Kit document scanner
    ocr_service.dart            scan-to-fill OCR: Cloud Vision if configured, else on-device
    image_storage_service.dart  persists scanned cover/page photos on-device
    update_service.dart         checks GitHub Releases, downloads + installs the APK
    apk_installer.dart          platform channel to the native install-APK intent
  state/library_provider.dart   app state (ChangeNotifier) wrapping the DB
  screens/                      library list/shelf, scan, book detail/edit, cover/page
                                 scanning, ISBN entry, categories, settings
  widgets/                      shared UI pieces
```

## Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
and Android SDK/platform tools (Android Studio is the easiest way to get
both).

```bash
flutter pub get
flutter run            # run on a connected device/emulator
flutter build apk       # release apk -> build/app/outputs/flutter-apk/app-release.apk
flutter build apk --debug
```

`flutter analyze` and `flutter test` both pass as of this scaffold. A
GitHub Actions workflow (`.github/workflows/build.yml`) builds a debug APK
and a release APK on every push/PR as a CI check and artifact — useful in
environments (like the one this scaffold was prepared in) where the
Android SDK itself isn't reachable, so the APK can't be built locally
there.

### Release builds

`.github/workflows/release.yml` builds a release `.apk` and publishes it
as a GitHub Release with the APK attached, either:

- automatically, on pushing a tag matching `v*.*.*` (e.g. `git tag v1.0.0
  && git push origin v1.0.0`), or
- manually, via the "Run workflow" button on the Release workflow in the
  Actions tab, entering a tag name.

The release build is signed with the Flutter debug keystore (see
`android/app/build.gradle.kts`), same as `flutter build apk --release`
locally — fine for prototype distribution, but replace it with a real
signing config before a production/Play Store release.

## OCR text scanning

The scan buttons next to Title, Authors, Illustrators, ISBN, and Publisher
in the book editor photograph that text and run OCR on it, then always show
the recognized text back to you in an editable dialog before it's applied —
scanning never silently overwrites a field.

By default this uses Google ML Kit's on-device text recognizer: free,
offline, and fast, but it only reads Latin-script text — Thai titles and
credits will come back empty or garbled. To get accurate Thai (and Latin)
recognition instead:

1. Create a Google Cloud Vision API key (Cloud Console → APIs & Services →
   Credentials, with the Cloud Vision API enabled on that project).
2. In the app, go to **Settings** and enter it under **Text scanning
   (OCR)**.

Once set, every OCR scan is sent to the Cloud Vision API instead of running
on-device, billed to that key's Cloud project. Clear the field to go back
to on-device recognition.

## App updates

QuetzaLib isn't distributed through the Play Store, so it can't rely on
Play's automatic update mechanism. Instead, **Settings → App update** lets
an existing install update itself in place:

1. Tap **Check for updates**. The app queries the GitHub Releases API
   (`/repos/LDKTC/App-QuetzaLib/releases/latest`, published by
   `.github/workflows/release.yml`) and compares its `tag_name` against
   the running app's version (`PackageInfo`/`pubspec.yaml`).
2. If a newer release has an `.apk` asset attached, tap **Download &
   install**. The APK is downloaded to the app's private cache
   (`<cache>/updates/`), then handed to Android's system package installer
   via a `FileProvider` content URI and the `android.permission.VIEW`
   `application/vnd.android.package-archive` intent (see `MainActivity.kt`
   and `android:name="android.permission.REQUEST_INSTALL_PACKAGES"` in
   `AndroidManifest.xml`).
3. The OS will prompt to allow "install unknown apps" for QuetzaLib the
   first time (Android's standard sideload-install flow), then shows the
   normal package-installer confirmation screen. Installing over the
   existing app keeps your local library/settings intact, same as any
   Android app update.

This only surfaces releases that are actually published — see
[Release builds](#release-builds) above for how a new version gets
tagged and built.

## Notes on this environment

This scaffold was prepared in a sandboxed remote session without access to
the Android SDK (`dl.google.com` is not reachable from it), so the APK
itself could not be built and run end-to-end here. What *was* verified in
this environment:

- `flutter pub get` resolves all dependencies cleanly.
- `flutter analyze` reports no issues.
- `flutter test` passes (ISBN utility unit tests + a library-screen widget
  test).

Building and running the actual `.apk` on a device/emulator, and
verifying the barcode scanner and network lookups against real hardware,
still needs to happen in an environment with the Android SDK — either
locally or via the included CI workflow.
