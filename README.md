# Singbook

**Website:** [freevia.org/singbook](https://freevia.org/singbook/) · **Privacy policy:** [freevia.org/singbook/privacy](https://freevia.org/singbook/privacy/) · **Support and feedback:** [freevia.org/singbook/support](https://freevia.org/singbook/support/)

**Get the app:** [Google Play for Android](https://play.google.com/store/apps/details?id=org.freevia.singbook) (public listing 0.2.15 in supported regions) · [Microsoft Store for Windows](https://apps.microsoft.com/detail/9P2J824JLQGZ) (public listing; Store version not exposed).

The [website](https://freevia.org/singbook/) shows real Android and Windows app screenshots using fictional sample-song content. The iOS version remains in development and is not on the App Store or TestFlight.

A local-first Flutter songbook for Android and Windows, with iOS in development. Search Genius, compare lyrics and chord arrangements from free sources, and keep each song in one portable ChordPro file. No Singbook backend is required. SQLite stores the local library; source HTTP requests run on the device.

## Develop and test

Windows desktop setup and current platform gaps are documented in the
[Windows desktop guide](docs/windows-desktop.md).

For macOS setup, simulator builds, and signing steps, see [iOS build preparation](docs/ios-build.md). Production listing copy, screenshot inventory, offline validation and the remaining publishing decisions are covered in the [App Store handoff](docs/ios-testflight.md#app-store-publishing-handoff--2026-10-19).

Use Flutter 3.44.8 / Dart 3.12, JDK 21 and Android SDK 36. The app ID is `org.freevia.singbook`. Android 24+ is supported. iOS builds require macOS/Xcode and target iOS 15+. Simulator debug and unsigned device release builds have been compiled with Flutter 3.44.8 and Xcode 27.1; iOS sign-in, sync, and localization still need device validation. See the [iOS build guide](docs/ios-build.md) for setup and validation details. The iOS project is prepared for Google sign-in (URL scheme and `GIDClientID` from `ios/Flutter/Secrets.xcconfig`, see [Google Cloud / OAuth setup](docs/google-oauth-setup.md)) and lists the 34 languages in `CFBundleLocalizations`; Runner now bundles a required-reason privacy manifest; a signing team and owner confirmation of the final release privacy answers are still needed. See [TestFlight preparation](docs/ios-testflight.md), the [App Privacy assessment](docs/ios-app-privacy.md), [submission details](docs/testflight-submission.md), and [iOS E2E evidence](docs/ios-e2e.md).

Singbook uses its open-book and floating-note artwork, navy/parchment
light theme and navy/amber dark theme. The database name and `x_verse` file
directives remain stable for saved-song compatibility.

The release application ID is `org.freevia.singbook`. Earlier test builds used
`org.freevia.verse`, so the release installs as a separate app and cannot read
that app's private library automatically. Share songs from the old app as
ChordPro files, or use its setlist sharing action, then import those files in
the new app through Settings > Import songs. A complete-library backup ZIP
action exists in code (`FileActions.shareBackup`) but has no UI entry point yet,
so neither the app nor the store listing offers it. Keep the old app and its data until the imported
songs, timing, provenance, and setlists have been verified.

Copy `config/defines.example.json` to `config/local.defines.json` and supply a Genius **client access token**. Do not supply a client secret. The local file is ignored by Git. A token bundled in a mobile binary is public configuration and can be extracted.

```powershell
flutter pub get
flutter gen-l10n
flutter test
flutter analyze
.\scripts\build-android.ps1 -Debug
.\scripts\build-android.ps1 # Release preview APK
flutter run -d emulator-5554 --dart-define-from-file=config/local.defines.json --dart-define=cronetHttpNoPlay=true
```

`scripts/build-android.ps1` runs Flutter in an owned process tree and configures
Gradle and Kotlin to exit with the build. It temporarily overrides conflicting
daemon settings in `GRADLE_OPTS`, preserves other caller options, and restores
the original environment after success or failure. Interrupting the script
cleans up its worker and descendants.

Deterministic fixture-E2E builds can opt into the temporary AGP 9 Cronet
workaround by setting `ORG_GRADLE_PROJECT_singbookFixtureE2e=true` for that build
only. Unset it afterward. It excludes a Cronet runtime dependency in debug
configurations, so leave it unset for normal builds and live-provider tests.

The release build is written to `build/app/outputs/flutter-apk/app-release.apk`.
Install a preview over an earlier preview with `adb install -r <apk-path>` to
preserve the local library. A release build stops with an error when
`config/local.defines.json` is missing (it would ship without the Genius token and
Google sign-in IDs); pass `-AllowMissingDefines` to build anyway.

### Release signing

Create `android/key.properties` (git-ignored, never commit it or the keystore):

```properties
storeFile=C:/path/to/upload-keystore.jks
storePassword=...
keyAlias=...
keyPassword=...
```

With that file the release build is signed with your key. Without it a release
build **fails**: Gradle never falls back to the debug key on its own. The only
way to get a debug-signed release APK (local preview, never distribute) is
`.\scripts\build-android.ps1` without `-Production` (it warns and passes
`-PallowDebugSigning=true`; bundles always need the key). For anything you
distribute run `.\scripts\build-android.ps1 -Production` (also sets
`-PrequireReleaseSigning=true`, which overrides `allowDebugSigning`). Release builds enable
R8 code and resource shrinking (`android/app/proguard-rules.pro`); if shrinking
breaks a plugin, build with `-PminifyRelease=false` and report the missing keep
rule. The rules were written without a device-verified release build, so check
networking (Cronet) and Google sign-in on a release APK before publishing.

### Google Play release

Next release: `0.2.24+38`. Every new release increments both the visible patch
version and the build number: `0.2.24+38`, `0.2.25+39`, and so on. The number after
`+` is the Play versionCode and must always increase; never reset it when the
visible version changes. Rebuilds of the same release and promotion between
internal testing and production keep the same version. Update `pubspec.yaml`,
`lib/ui/app_version.dart`, `lib/providers/transport.dart`, and this example
together before building; the version-drift tests check the displayed and HTTP
versions. Do not renumber historical releases or overwrite verified artifacts.

The target API is 36, `minSdk` 24, with native debug symbols and
a locale config for all 34 app languages (one per `lib/l10n/app_*.arb`; keep
`localeFilters` in `android/app/build.gradle.kts` and
`res/xml/locales_config.xml` in sync when adding a catalog).

```powershell
.\scripts\build-android.ps1 -Bundle -Production   # signed .aab + symbols + SHA-256 in artifacts\
.\scripts\verify-release.ps1 -Path artifacts\singbook-0.2.24+38-release.aab
```

The build script refuses to overwrite an existing artifact of the same version
(pass `-Force` deliberately). `verify-release.ps1` checks the signer is not the
debug key, `targetSdkVersion >= 36`, the debuggable flag, and the 16 KB ELF
segment alignment of the 64-bit native libraries; for an `.aab` it needs
`bundletool` (on `PATH` or a `bundletool*.jar` in your home folder) and reports
`UNVERIFIED` and fails without it. Continuous integration runs analysis, the
complete Linux and sharded Windows test suites, Windows native smoke checks,
and a desktop journey. It also builds an unsigned Windows portable bundle;
the separate macOS lane builds an unsigned universal app. Store packaging
reuses the pinned Windows bundle instead of compiling it again. These jobs
do not sign or submit store releases. See the [integration and release
pipeline](docs/release-pipeline.md) for validation gates and artifact reuse.

Store listing text and the public privacy policy (Markdown and hostable HTML)
are in [docs/play-store](docs/play-store). The published
policy at [freevia.org/singbook/privacy](https://freevia.org/singbook/privacy/)
is the canonical public version. Reconcile both copies whenever the app's
sources, data handling or sync availability changes.

### Android backup

`android:allowBackup` is `true`: the local library (SQLite database and
preferences) is the user's data and should survive a reinstall or device change,
so it is included in Android Auto Backup and device-to-device transfer. Caches
and temporary files are excluded (`android/app/src/main/res/xml/backup_rules.xml`
for Android 11 and older, `data_extraction_rules.xml` for Android 12+). Singbook
has no credential or secure-storage dependency (Google sign-in tokens
are held by the platform, not by Singbook); keep it that way, or add
exclusions for anything sensitive that is later stored.

No tokens or secrets are stored, but the optional Google Drive sync binding
(hash and e-mail of the linked account, key `sync.account`) and the per-item sync
baselines (`sync_items`) live in the same library database, so they are part of
the backup and cannot be excluded by file path without excluding the songs. After
a restore on another device they can claim items are already synced for an
account that is not signed in there; the app is expected to reset them on the
first launch after a restore (a marker in `noBackupFilesDir` detects it).
The privacy policy states that the account e-mail may be included in backups.

`cronetHttpNoPlay=true` embeds Cronet so Android networking works without Google Play Services. iOS uses URLSession. Native networking handles the HTTP early responses returned by some sources. Test fixtures do not replace production network requests.

```powershell
flutter test integration_test/app_device_test.dart -d emulator-5554 --dart-define-from-file=config/local.defines.json --dart-define=cronetHttpNoPlay=true
flutter test integration_test/provider_device_test.dart -d emulator-5554 --dart-define-from-file=config/local.defines.json --dart-define=cronetHttpNoPlay=true
```

`integration_test/provider_device_test.dart` is a manual live smoke test, not a CI gate: it hits the real third-party sites, tolerates individual providers being down (it asserts a minimum number of working providers, not exact counts) and skips Genius checks when `GENIUS_ACCESS_TOKEN` is absent. It logs status/counts only, never lyrics or credentials. See [source capabilities and limits](docs/sources.md).

## Song storage and exchange

Every song is a `.cho` file: normal ChordPro title/artist/chords/lyrics plus versioned `{x_verse}` / `{x_verse_data}` directives containing timing, source records, provenance and unrecognized fields. Timing retains original data alongside normalized microsecond cues. Choosing a chord sheet does not discard alternatives. Recording-specific facts and timing are combined only when the identity checks support them. Chord-only edits preserve timing; lyric changes make existing bindings stale.

Import accepts ChordPro, plain text, LRC, enhanced LRC and TTML. Sharing and copying a song include its complete single-file payload. Ordinary setlist sharing uses OpenSong `.osts` references and requires matching songs in the receiving library. Complete collection packages contain a manifest and self-contained `.cho` songs in one ZIP; import validates hashes and paths before an atomic database transaction. Conflicting imported songs preserve local edits as separate copies. PDF printing uses bundled offline Noto fonts.

## Accounts

Songs work without signing in. Google Drive sync is optional and is available when the build is configured with the public OAuth client IDs (`VERSE_GOOGLE_SERVER_CLIENT_ID`, and `VERSE_GOOGLE_IOS_CLIENT_ID` for iOS) in `config/local.defines.json`; without them the app shows sync as not configured. Sync defaults to each person's private Drive app-data folder; Android users can choose a visible folder through Google Picker. When switching folders, Singbook keeps the previous copies as a backup. It uses the narrow `drive.appdata` and `drive.file` scopes, not a shared Singbook account; no client secret or application backend is involved. Songs and setlists are stored as individual files. After you connect, song additions, edits and removals sync automatically with a short debounce; Sync now is also available. In a visible folder, users can import ChordPro files explicitly from Drive; Singbook tracks only files it created or the user selected. Starting the app and returning to it do not start cloud sync. Concurrent edits are kept as separate conflict copies. See [Google Cloud / OAuth setup](docs/google-oauth-setup.md) for the owner's configuration steps and [sync design](lib/sync/SETUP.md). `scripts/print-signing-fingerprints.ps1` prints the signing SHA-1s that Android OAuth clients need. Configured, signed Apple builds also offer optional iCloud sync using the app’s private CloudKit database. It requires the existing Apple developer team, container, entitlements and matching signing profile. Disconnecting preserves local and cloud copies.

## Languages and themes

User-visible strings belong in `lib/l10n/app_*.arb`; run `flutter gen-l10n` after changes. Catalogs for 34 languages are included and selectable by their native names. Irish and Maltese plural grammar still needs native-speaker review before release. UI colors use theme tokens, with light/dark/system mode and selectable palettes. Reader typography is independent of the application text scale.

Layouts adapt to the available window width, including tablet portrait and
split-screen windows. Navigation uses a rail from 600 logical pixels; song and
setlist collections use columns when their content area has at least 640 pixels.
The editor and source comparison use side-by-side panes when space permits.
Lyrics keep a readable maximum width while retaining their original line order.
Android layout tests cover 800×1280, 1280×800 and 600×960 windows with enlarged
Ukrainian text, the keyboard, and the existing phone layouts.

Bundled Noto fonts are distributed under the SIL Open Font License in `assets/fonts/LICENSE`. Source content retains its provider attribution and any supplied rights metadata; availability is not a redistribution license.

## Legal and source terms

Singbook fetches lyrics and chord sheets on the user's device from third-party
APIs and public web pages. Some of those integrations are unofficial (page
extraction, undocumented web endpoints) and may conflict with a provider's terms
of service; they can be denied or change at any time and are reported as
`blocked`, `access_denied` or `extraction_failed`. YouTube Music requests are
anonymous; consent interstitials and challenges are reported as provider
failures without a browser flow or cookie transfer. Fetched text is recorded with
rights status `unknown` unless the source declares an open license. Singbook does
not grant any license to it: saving it, printing it, and above all sharing or
exporting it (`.cho`, collection packages, PDF) is the user's responsibility. See
[source capabilities and limits](docs/sources.md#legal-and-terms-of-service-posture)
and set `SINGBOOK_CONTACT_URL` in `config/local.defines.json` so API operators
(MusicBrainz, Wikimedia) can contact the app's publisher.

The app wordmark uses Singbook Serif, a static bold instance derived from
[Lora](https://github.com/google/fonts/tree/main/ofl/lora) and renamed for this
build. Its copyright and SIL Open Font License are retained in
`assets/fonts/SingbookSerif-OFL.txt`. Print headers retain the Singbook Brand
serif derived from Libre Baskerville, with its license in
`assets/fonts/LibreBaskerville-LICENSE.txt`. Both fonts are bundled for offline use.

Appearance-font provenance and reproduction steps are documented in
[appearance fonts](docs/appearance-fonts.md). Font files and their licenses remain
bundled for offline use.

## License

Singbook's original source code, documentation, and app artwork are licensed under the
[Apache License 2.0](LICENSE). The bundled fonts retain their own SIL Open Font
Licenses in `assets/fonts`; see [NOTICE](NOTICE) for attribution. This license
does **not** cover songs, lyrics, chord charts, cover art, or other content
retrieved from third-party services. Availability through a source is not a
license to copy, redistribute or use that content.
