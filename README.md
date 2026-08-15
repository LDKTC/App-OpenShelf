# OpenShelf

Android app (Flutter, built as an `.apk`) that scans the ISBN barcode on
the back of a book, looks up its metadata, and adds it to your personal
library, stored locally on-device in SQLite.

## Features

- **Scan-to-add**: scan an ISBN-10/13 barcode with the camera and look up
  the book automatically.
- **Metadata lookup**:
  - International/English books: [Google Books API](https://developers.google.com/books) first,
    falling back to [Open Library](https://openlibrary.org/dev/docs/api/books).
  - Thai books (ISBN group `978-616` or `978-974`): queried against the
    [National Library of Thailand](https://nlt.primo.exlibrisgroup.com/nde/home?vid=66NLT_INST:66NLT&lang=th)'s
    Alma catalog via the SRU protocol first, since Thai-language titles are
    far more complete there than in the international catalogs. See
    [NLT SRU configuration](#nlt-sru-configuration) below — this needs a
    one-time setup step.
- **Manual add/edit**: for books with no barcode or no metadata match.
- **Library management**: categorize books (custom categories you define),
  search/filter by title, author or ISBN, and track reading status
  (Unread / Reading / Read).
- **Fully local**: all data lives in an on-device SQLite database
  (via `sqflite`) — nothing is synced anywhere.
- **In-app updates**: since OpenShelf isn't distributed through the Play
  Store, **Settings → App update** checks GitHub Releases for a newer
  build and installs it over the existing app — see [App updates](#app-updates)
  below.

## Tech stack

- Flutter (Android target only), Material 3
- `sqflite` for local storage
- `mobile_scanner` for barcode scanning + `permission_handler` for the
  camera permission
- `provider` for state management
- `http` + `xml` for metadata lookups (Google Books JSON, Open Library
  JSON, NLT Alma MARCXML-over-SRU)
- `package_info_plus` + `path_provider` for the in-app updater (current
  version check, downloaded-APK staging)

## Project layout

```
lib/
  models/            Book, BookCategory, ReadStatus, BookMetadata, AppUpdateInfo
  services/
    database_service.dart       sqflite schema + CRUD
    isbn_utils.dart             ISBN validation/normalization, Thai-ISBN detection
    settings_service.dart       persisted app settings (NLT SRU URL)
    book_metadata_service.dart  orchestrates provider lookup order
    metadata_providers/         google_books, open_library, nlt_alma_sru
    update_service.dart         checks GitHub Releases, downloads + installs the APK
    apk_installer.dart          platform channel to the native install-APK intent
  state/library_provider.dart   app state (ChangeNotifier) wrapping the DB
  screens/                      library list, scan, book detail/edit, categories, settings
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
as a (pre-release) GitHub Release with the APK attached, either:

- automatically, on pushing a tag matching `v*.*.*` (e.g. `git tag
  v0.1.0-prototype && git push origin v0.1.0-prototype`), or
- manually, via the "Run workflow" button on the Release workflow in the
  Actions tab, entering a tag name.

The release build is signed with the Flutter debug keystore (see
`android/app/build.gradle.kts`), same as `flutter build apk --release`
locally — fine for prototype distribution, but replace it with a real
signing config before a production/Play Store release.

## NLT SRU configuration

The National Library of Thailand's Alma SRU endpoint (needed for Thai-ISBN
lookups) is specific to their Alma tenant and isn't publicly documented, so
it ships unset — Thai lookups fall back to Google Books/Open Library until
you configure it. To set it up:

1. In the app, go to **Settings**.
2. Enter the SRU base URL in the field provided. Alma SRU URLs follow the
   pattern `https://<region-cluster>.alma.exlibrisgroup.com/view/sru/<institution_code>`.
   NLT's Primo institution code is `66NLT_INST` (from the Primo VID in
   `https://nlt.primo.exlibrisgroup.com/nde/home?vid=66NLT_INST:66NLT`),
   but the region cluster (`na01`, `eu03`, `ap01`, etc.) isn't derivable
   from the Primo URL — get the exact SRU base URL from NLT/Ex Libris
   support, or from Alma's own admin UI under
   **Resources Configuration → Search → SRU**, if you have Alma admin
   access.
3. Tap **Test connection** to confirm the endpoint is reachable and
   returns a well-formed SRU response.

If left unset, or if a request to it fails, the app silently falls back to
Google Books and Open Library — Thai lookups just won't be as complete. If a
scanned Thai ISBN (978-616 / 978-974) has no match anywhere and the SRU URL
isn't configured yet, the Scan screen says so explicitly and offers a button
straight to Settings, instead of just reporting a generic "not found".

## App updates

OpenShelf isn't distributed through the Play Store, so it can't rely on
Play's automatic update mechanism. Instead, **Settings → App update** lets
an existing install update itself in place:

1. Tap **Check for updates**. The app queries the GitHub Releases API
   (`/repos/LDKTC/App-OpenShelf/releases/latest`, published by
   `.github/workflows/release.yml`) and compares its `tag_name` against
   the running app's version (`PackageInfo`/`pubspec.yaml`).
2. If a newer release has an `.apk` asset attached, tap **Download &
   install**. The APK is downloaded to the app's private cache
   (`<cache>/updates/`), then handed to Android's system package installer
   via a `FileProvider` content URI and the `android.permission.VIEW`
   `application/vnd.android.package-archive` intent (see `MainActivity.kt`
   and `android:name="android.permission.REQUEST_INSTALL_PACKAGES"` in
   `AndroidManifest.xml`).
3. The OS will prompt to allow "install unknown apps" for OpenShelf the
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
