# iOS end-to-end testing

Use a dedicated simulator without a user library. The test suites create
temporary fixture databases. Do not run this against a physical installation
or a simulator containing a user's library. The runner keeps the installed app
with `--no-uninstall` and serializes the suites against one build directory.

```sh
export PATH="/Users/tony/development/flutter/bin:$PATH"
flutter devices
python3 scripts/run-ios-e2e.py \
  --device <dedicated-simulator-uuid> \
  --output artifacts/ios-e2e-<unique-run-name>
```

The default combined target is `integration_test/ios_full_device_test.dart`.
Use an unused output directory so verified evidence cannot be overwritten.
Pass `--defines config/local.defines.json` when the local release configuration
exists. The runner never prints configuration values. Each iOS checkpoint awaits the native screenshot API before advancing, saves
the PNG inside the test app container, and emits a
`SINGBOOK_E2E_NATIVE_CAPTURE` marker. The host copies that completed file into
the evidence directory and checks its PNG signature. This avoids host log and
`simctl screenshot` delays capturing a later screen. The run records a log and
JSON summary. A failed copy or missing/invalid file for an emitted checkpoint fails the
runner. A suite that emits no screenshot markers is not screenshot-verified. Review the images; successful screenshot creation alone is not visual QA.

## Coverage

| Suite | Scope |
| --- | --- |
| `app_device_test.dart` | Native SQLite library/settings persistence, light/dark/localization state, enlarged text, logical phone/tablet/split-window sizes, keyboard and rotation layouts. Logical tablet sizes do not substitute for a native iPad run. |
| `singbook_journey_device_test.dart` | Fixture-provider search, failure/retry, comparison, provenance and safe metadata enrichment, save/edit, favorite, player and timing, setlist operations, settings/reload, ChordPro and collection-package round trips, PDF generation. Import bytes enter the public controller API; this does not operate the OS document picker. |
| `ios_android_parity_device_test.dart` | Deterministic native parity target: the complete fixture journey, settings/setlists/player tests, native platform contracts, real fullscreen/orientation checks, and native layout captures. No live source or cloud account is used. |
| `ios_provider_parity_device_test.dart` | Actual LyricsPlus parsing/word timing, channel-7 cache migration with retained library data, and Start Jamming chord-only comparison/save/SQLite round trip, using synthetic HTTP responses on native iOS. This does not establish live network availability. |
| `ios_channel9_provider_device_test.dart` | Chords and Tabs channel-9 UI search/comparison/save with native SQLite close/reopen and ChordPro provenance retention; explicitly invoked, default-disabled OpenScore composition/rights/text retention. Synthetic HTTP only; no live source availability claim. |
| `android_parity_features_device_test.dart` | Unified Recent/Library/Favorites/Online modes, persisted startup selection, Settings section routes and text size/chord controls, inferred key and estimated duration, collapsed player controls, speed/section seeking, inline setlist rename, accessibility reorder actions, and song deletion confirmation. |
| `transpose_popup_device_test.dart` | Chord transposition, restored preferences, keyless/known-key songs, large RTL text, logical landscape and actual native portrait/landscape. |
| `ios_native_layout_device_test.dart` | Actual native window sizes without surface overrides, portrait/landscape, English/light, Ukrainian/dark at 150%, Arabic/dark at 160%, reader scrolling and editor metadata reachability. |
| `ios_platform_device_test.dart` | Real iOS plain-text clipboard path and native PDF rasterization through the printing plugin; native temporary file access. |
| `source_catalog_device_test.dart` | Live Unison TTML through the platform HTTP client; fixture catalog refresh atomicity and offline cache behavior. |
| `provider_device_test.dart` | Live attributed open-song canary; broader provider comparison requires the Genius build token and may skip on upstream outage/catalog change. Skips are not passes. |

Android rich HTML clipboard methods are not implemented on iOS. Its existing
Android-only native channel test is excluded; the iOS plain-text fallback has
its own native test. Do not call a fixture-provider success a live-provider
verification.

## Interactive native dialogs

The opt-in test below opens the real document picker, share sheet, and print
dialog. An operator must cancel each one after the matching
`SINGBOOK_NATIVE_DIALOG` marker. A second test saves an original ChordPro
fixture through Save to Files on the local device, then selects it through the
real document picker and verifies exact content, song ID, title, and body.
Choose a local Files destination, not a cloud or messaging destination.
Nothing is sent to another person or printed. No real print job is attempted.

```sh
flutter test integration_test/ios_native_dialog_device_test.dart \
  -d <dedicated-simulator-uuid> --no-uninstall \
  --dart-define=SINGBOOK_NATIVE_DIALOG_QA=true --reporter expanded
```

Codex computer-use access to Device Hub is needed to automate those native
buttons with Xcode 27.1. Access was initially denied, then worked after the
desktop app restart on 2026-10-19. The interactive tests are skipped by default
and are not part of the unattended suite.
Opening/cancelling dialogs does not establish successful import/export/printing
to a real destination. The local Files round trip verifies one destination;
other export targets, physical-device providers, and real printer output
remain separate checks.

## Evidence — 2026-10-18

Base: public commit `7253b4f1cfcad3ed56c187eefc1e4890c930920f`, app `0.2.6+20`,
Flutter 3.44.8 / Dart 3.12.2, Xcode 27.1, iOS 27.1 iPhone Duo simulator.

- Initial install attempt failed because the runtime remounted and the
  simulator shut down. Runtime scanning/remounting and rebooting recovered it.
  A signature verification error and a cancelled iOS 27.0 fallback download
  are retained as infrastructure diagnostics; no simulator security checks
  were disabled and no unrelated app simulator was reset.
- The first combined run finished with six passes, one Genius-related skip,
  and two harness failures. The failures were an obsolete editor split-layout
  assertion and a provider-list assertion against an unbuilt off-screen row.
- Corrected the editor test to inspect the current stacked metadata/lyrics
  geometry, use binding surface sizing for native rendering, and clean up its
  temporary database/controllers. Corrected the journey to scroll its source
  checks before asserting row content and clean up its database/controllers.
- First-run evidence: ignored `artifacts/ios-e2e-20261018-full/`.
- The corrected run at `artifacts/ios-e2e-20261018-corrected/` could not
  launch because its simulator's Mach server died; no test results are claimed.
- A fresh dedicated simulator (`Singbook E2E Fresh`, iOS 27.1 build 24A94232)
  ran seven tests successfully, skipped Genius without its token, and exposed
  one further journey harness failure: a clipped close control left a modal
  sheet over the page swipe. Evidence: `artifacts/ios-e2e-20261018-fresh/`.
  The test now dismisses the visible modal barrier and asserts the sheet is gone.
- Early host-triggered screenshot names could lag behind the tested UI on this
  heavily loaded host. The final rerun uses awaited native PNG capture, rather
  than relying on delayed host screenshot timing.
- The awaited-capture run at `artifacts/ios-e2e-20261018-final/` finished
  with seven passes, one missing-token skip, and a journey timeout in its
  two-second scroll settlement helper at the setlist picker. All 51 emitted
  native PNGs were copied and validated. The helper now waits for stable
  target geometry and keyboard insets instead of all caret frames stopping.
- Final verification at `artifacts/ios-e2e-20261018-verified/` exited zero:
  **8 passed, 1 skipped, 0 failed**. Genius was skipped because the local
  access token is unavailable. Live Unison TTML and the attributed open-song
  canary passed. All **58 native screenshot checkpoints** were copied and
  validated; five contact sheets and representative full-size images were
  visually reviewed across light/dark, Ukrainian, enlarged text, RTL, logical
  phone/tablet/split layouts, editor/picker states, and actual native rotation.
  Logical surface sizes are letterboxed on this simulator; those black margins
  are test viewport evidence, not proof of a native iPad layout.
- Rebuilt and launched the ordinary app after the tests on `Singbook E2E Fresh`;
  the empty home screen was visually checked. Evidence:
  `artifacts/ios-preparation/final-normal-launch.png`. The simulator is left
  running for inspection; all temporary build/device reservations are released.
- Displayed-version and User-Agent drift checks passed (two focused tests).
  The unsigned final archive rebuilt and passed the 18-manifest inspection;
  details and hashes are recorded in `docs/ios-testflight.md`.
- Final integration-test static analysis passed after these corrections.
- The earlier full unit/widget suite had 1,255 passes and four existing golden
  image differences. An additional regression attempt during this work was
  interrupted to relieve severe host load, and is not counted as a passing run.

This is the complete unattended target available with the current configuration,
not completion of every release acceptance flow. Keyboard-layout assertions
and focused-field screenshots do not replace native keyboard interaction QA.
At the end of that initial run, no signed distribution build, physical-device
OAuth callback, Google Drive sync, VoiceOver session, or native iPad session
had been validated. The subsequent native iPad results are recorded below. The Apple
developer account and local Genius/OAuth configuration remain unavailable.

## Native UI follow-up — 2026-10-19

After the desktop app restart, Device Hub access succeeded. On the same
dedicated Singbook simulator, the opt-in cancellation test passed: the real
document picker returned null, the share sheet returned dismissed, and the
print dialog returned false after cancellation. The PDF preview was visible.
No printer or recipient was selected. Evidence:
`artifacts/ios-native-dialogs-20261019/native-dialog-test.log` (exit zero, one
passed). The controls were observed and operated through approved Computer Use.

The additional Files success-path test also passed (one test, exit zero):
Save to Files wrote `Singbook Files QA 20261019.cho` to **On My iPhone**;
the native document picker selected it again. The test verified exact
exported ChordPro text and preserved song ID, title, and body after decoding.
The original 489-byte fixture is left in the dedicated simulator's local
Files storage. Evidence: `artifacts/ios-native-dialogs-20261019/native-files-roundtrip.log`.
This was a local file handoff, with no cloud provider, recipient, or printer.
The two interactive tests passed in separate runs; the unattended result
remains eight passes and one missing-Genius-token skip. Static analysis of the
interactive test passed. Successful printing to a physical printer, other
share destinations, VoiceOver and OAuth/Drive remain unverified. The subsequent native iPad matrix is recorded below.

The normal simulator app rebuilt successfully after these tests and was
installed over the test runner without uninstalling. Build evidence:
`artifacts/ios-native-dialogs-20261019/normal-simulator-build.log`.
The normal home screen was then verified through Device Hub. The simulator
is left running; all temporary build/device reservations are released.


## Expanded phone and tablet QA

The combined target also runs the native layout suite. On an iPad preserving
multitasking, use a local defines file containing `SINGBOOK_HOST_ROTATION: true`
and operate Device Hub rotation after each `SINGBOOK_NATIVE_ROTATE` marker.
The test checks actual native dimensions before continuing; it does not count
a logical viewport resize as native rotation.

`integration_test/ios_interactive_device_test.dart` combines native dialog checks
with the real app menu workflow. Enable `SINGBOOK_NATIVE_DIALOG_QA` in the
local defines file. The workflow covers account-unavailable state, song/setlist
share cancellation, backup export, restore preview cancellation, merge with
preferences, replacement confirmation cancellation and successful replacement,
and song/setlist imports through their app menus. All libraries and fixture
files are temporary original QA data. Save only to local Files.

For `SINGBOOK_APP_UI_WAIT` stages, inspect and complete the native action first,
then acknowledge the exact stage with:

```sh
python3 scripts/ack-ios-qa.py --device <uuid> \
  --log <evidence-directory>/ios_interactive_device_test.log \
  --stage <observed-stage-name>
```

The helper validates the sandbox path before writing the acknowledgement. It
does not operate or verify a dialog. Acknowledgements must never substitute
for visually confirming that the action succeeded. The runner also requires
an explicit `All tests passed!` result: an interrupted zero-exit process is not
success. The interactive target is separate from the unattended target and needs its own successful evidence.


## Native iPhone and iPad verification — 2026-10-19

Base remains public commit `7253b4f1cfcad3ed56c187eefc1e4890c930920f`;
app `0.2.6+20`, Flutter 3.44.8, Xcode 27.1. Dedicated simulators used the
standard iOS/iPadOS 27.0 runtime, build 24A434:

- iPhone 17 Pro: `9F62041B-4304-46D3-BA5C-B7FC3D5E8F0B`, actual windows
  1206×2622 portrait / 2622×1206 landscape.
- iPad Air 11-inch (M3): `E49D1BB1-2DFC-4087-9058-42BED3A4AF5A`, actual
  windows 1640×2360 portrait / 2360×1640 landscape. Device Hub rotation was
  operated after the host-rotation markers, preserving iPad multitasking.

### Results and corrections

The expanded native iPhone run found a real 10-pixel landscape NavigationRail
overflow that partially clipped Settings. The shell now subtracts safe-area and
keyboard insets from its navigation height budget. All 34 screen widget tests
passed, including a regression that checks Settings remains tappable with
native iPhone safe-area insets.

On each device, all nine unattended test cases have passing verification
results across the combined and focused runs; Genius remains skipped because
its local token is unavailable. This is not a claim that every intermediate
combined run passed:

- iPhone `iphone-corrected`: eight passes, one Genius skip, one layout-harness
  failure caused by tapping an off-screen large-text library row. The real
  navigation overflow was absent after the fix. `iphone-layout-final` then
  passed with all 48 native checkpoints, scrolling library/setlist rows into
  view and checking that they are tappable.
- iPad `ipad-full`: eight passes, one Genius skip, one journey-harness failure
  that asserted lyrics before asynchronous SQLite save completion. A focused
  retry exposed the same race for chord preferences. The journey now waits
  for actual persisted state for asynchronous UI mutations.
  `ipad-journey-verified` passed, including save/edit, player, favorites,
  setlist changes, settings and restart hydration (35 native checkpoints).
- The iPad native layout section completed all 48 checkpoints. Four host
  container-lookups exceeded the original 15-second limit; all four exact
  awaited PNGs were recovered from the same app capture session. The original
  failed summary remains unchanged; `ipad-full/capture-recovery.json` records
  recovery. The runner now allows 60 seconds for this lookup.

All 48 native layout images per device were visually reviewed, including
representative full-size reader/editor images. Light English, dark Ukrainian
at 150% text, and dark Arabic/RTL at 160% text were checked in both
orientations. The long-song fixture scrolls to its final lyric above the
player controls; lower editor metadata also remains reachable. No remaining
confirmed clipping or unreachable control was found in this matrix. This is
three locale/appearance profiles, not every supported translation or text size.

Evidence is ignored under `artifacts/ios-phone-ipad-20261019/`; the native
layout contact sheets are in `iphone-visual-review/` and `ipad-visual-review/`.
The source and test changes are tracked; generated screenshots, logs, archives,
local defines and signing material are not committed.

### Native Files, share and backup coverage

On both standard-device simulators, the first two interactive cases passed:
real picker/share/print cancellation, followed by a successful local Files
save/reselect round trip that preserved the exact ChordPro payload and song
metadata. No printer, recipient or cloud storage destination was selected.

The iPad app-menu workflow additionally verified song/setlist sharing
cancellation, account-unavailable UI, local backup export, preview cancellation,
merge with preferences (newer local song retained and dark theme restored),
replacement-confirmation cancellation, and confirmed replacement (extra QA
song removed, original song/setlist intact). All corresponding assertions and
checkpoints completed. Song import through the app menu also preserved its ID
and body; the imported setlist appeared correctly.

That original combined workflow did **not** finish successfully: its final
setlist-ID assertion expected the decoder ID instead of the stable content ID
assigned by the controller. The corrected source separates backup and import
cases, checks observed imported content/identity, and repeats the setlist
import to assert stable identity and no duplicate. Completion events are
retained so operator delay cannot miss a transient success snackbar. Fixture
filenames contain the session to avoid collisions on rerun.

A focused native-import rerun reached its first save stage, then the Mac
locked. Computer Use reported it could not unlock the Mac automatically.
The blocked run was stopped; native repeat-import verification and completion
of the expanded iPhone backup/import workflow remain pending an unlocked Mac.
The earlier phone workflow also has an interrupted backup-save attempt and a
menu-selector/animation-wait harness correction; neither is counted as a
passing whole workflow. Failed and interrupted logs are retained.

The remaining native UI run can use
`integration_test/ios_import_workflows_device_test.dart` for imports alone,
or `integration_test/ios_app_workflows_device_test.dart` for both independent
app-workflow cases. Use the defines and acknowledgement procedure above.
Operator acknowledgement waits allow ten minutes and fail immediately if not
confirmed; the runner rejects interrupted output even if Flutter exits zero.

Authenticated Google sign-in/Drive sync, Genius without a token, VoiceOver,
physical hardware, real printer output and nonlocal Files/share destinations
remain outside this simulator verification. The earlier four golden-image
baseline differences are still recorded; no blanket all-application acceptance
claim is made from these passing simulator checks.

### Final build verification

The final unsigned archive built successfully with the navigation fix as
`0.2.6 (20)`, bundle ID `org.freevia.singbook`, minimum iOS 15.0. The privacy
inspector verified all 18 bundled manifests and an exact match between the
archived root manifest and the reviewed source. The archive binary SHA-256 is
`5d4e80a0e32a3ae8be06580dbb316571f0444d6a9ff480319d65b0fa2012b459`.

The ordinary simulator build also succeeded. It was installed without
uninstalling either dedicated QA app. Both normal apps reached their empty home screens and their fresh native
screenshots were reviewed. Debug simulator
launch verification uses Flutter to start the debug runtime; a bare simctl
launch initially showed only the launch screen.

### Resumed native verification — 2026-10-19

After the Mac was unlocked, the remaining native import and backup checks
completed under the existing shared system load. These results resolve the
native-workflow pending items above; earlier failed/interrupted evidence is
retained rather than reclassified.

- iPad Air 11: `ipad-native-resumed/` completed both app-workflow cases with
  `All tests passed!`, exit 0 and eight valid native PNG checkpoints.
- iPhone 17 Pro: `iphone-native-resumed/` passed the independent import case,
  including repeat import. Its backup case failed because the expected restore
  dialog was absent after a picker/orientation transition (`No element` at the
  replacement-mode selector). The whole two-case run remains failed.
- iPhone focused backup rerun: `iphone-backup-verified/` completed the backup
  case with `All tests passed!`, exit 0 and six valid native PNG checkpoints.
  Host-controlled rotation occurred before opening the portrait picker, and
  the operator wait pumped Flutter frames while native results returned.

On both devices, native Files saved original ChordPro and setlist fixtures;
the app menus imported the song with its ID/body intact and the setlist with
its notes, song link and key override. Reimporting the same setlist retained
its observed stable ID and exactly two setlists (baseline plus imported).
Backup export, preview cancellation, merge with restored preferences,
replacement-confirmation cancellation, and confirmed replacement all have
passing assertions. Merge retained the extra temporary song and restored dark
theme; replacement removed that extra song while preserving the original
song body and setlist ID. All libraries used disposable test databases.

The sixteen checkpoints comprising the successful iPad cases, successful
phone backup rerun and phone import case were visually reviewed in contact
sheets, with the phone replacement confirmation also inspected at full size.
No additional product defect was found in these native workflows. Native
Files required a distinct backup name because earlier QA exports used the
same date-based default name. Keyboard capture was returned to off.

The test runner now accepts `--test-name 'exact test name'` to run a focused
case while retaining the normal completion-marker and screenshot checks.
Dart analysis of the modified workflow test, Python compilation of the runner,
and whitespace checks passed. This follow-up changes test infrastructure and
this report only. All temporary file/build/device reservations are released.
Authenticated provider flows, physical-device/VoiceOver checks, printer output,
nonlocal Files destinations and the previously recorded golden differences
remain outside these results.

## Android parity integration — 2026-10-19

Integrated upstream `dbb3ff5` (Android `0.2.8+22`) into the iOS preparation
branch, preserving the iOS signing/privacy work. Shared Flutter changes include
unified Songs startup, larger player controls, Settings submenus and About,
consistent Delete actions, compact/reorderable setlists with inline titles,
duration/instrumental timing and combined source metadata with estimated keys.
Windows-only networking, clipboard and close handling remain platform-specific.

The new iOS visible-folder/file adapter uses the existing account-bound grant
implementation with a native ASWebAuthenticationSession transport and device-only
Keychain. It keeps `drive.file` separate from private-folder identity auth,
validates callback state and PKCE, checks the actual Drive account/folder,
and clears the file grant on sign-out. No live OAuth claim is made without
a configured iOS client. Local Files import/export remains independent of OAuth.

`integration_test/ios_parity_device_test.dart` combines native Keychain/invalid
callback checks, real clipboard/PDF/filesystem checks, original-content store
captures and full native layout profiles. The layout suite now enters unified
Songs directly because the Home destination was removed upstream.

The iPhone and iPad parity suites each passed six native tests. Successful runs:
`artifacts/ios-parity-20261019/iphone-v3/` and `ipad-v2/`. Each includes 42
layout checkpoints plus four original-content store captures. Phone native sizes
were 1320×2868 and 2868×1320; iPad sizes were 2048×2732 and 2732×2048.
All 84 layout images were inspected in contact sheets with representative native
images inspected separately, including large RTL and Ukrainian layouts. Eight
store captures were reviewed and packaged as RGB without resizing or cropping.
Test-pointer fade frames are rendered before capture, preserving app pixels.

The first native attempt used stale Library navigation; test selectors were
updated for unified Songs/Recent. The first iPad layout attempt used app-only
orientation requests, which iPad multitasking ignores. Its successful rerun
used `SINGBOOK_HOST_ROTATION=true` with Device Hub rotation of only the
dedicated Singbook simulator. Prior failed logs remain preserved.

The first full host suite reported one real-time debounce count failure under
load. Its test now controls only the debounce timer while retaining real
database/sync work and the exact one-list/five-song assertions. All 19 focused
controller tests passed. No runtime debounce behavior was changed.

Final full host suite: **1,531 passed, 13 platform-specific skips**, using
`--concurrency=4`; evidence: `artifacts/ios-parity-20261019/all-tests-final.log`.
Focused analysis reported no issues, localization regeneration completed, and
the store validator accepted all eight refreshed screenshots at `0.2.8+22`.
Both dedicated simulators were restored to their initial shutdown state and
Device Hub’s prior simulator selection was restored. Temporary device/build
reservations are released after the final archive check.


## Merged Android-feature coverage — 2026-10-19/20

Application base: public main merge `e6a15c7b389af33e054417aa6f136ae0abc86075`,
version `0.2.8+22`. This run changes only integration tests and this report;
`lib/`, `ios/`, and `android/` remain identical to that merged application.
Flutter 3.44.8, Xcode 27.1, iOS/iPadOS 27.0. Evidence is retained under the
ignored directory `artifacts/ios-merged-e2e-20261019/`.

Dedicated native devices: iPhone 17 Pro Max (1320×2868) and iPad Air 13
(2048×2732); landscape reverses those dimensions. Temporary SQLite libraries
and original fixtures were used throughout, with `--no-uninstall`. Legacy
`org.freevia.verse` data and unrelated simulators were left alone.

The new three-test parity suite covers all four Songs modes, startup preference
restoration, Settings navigation and controls, About content, inferred key and
estimated duration, collapsed player controls, speed adjustment, instrumental
section seeking, inline setlist rename, accessibility reorder actions, and song
delete cancellation/confirmation. The full journey additionally verifies safe
metadata enrichment when combining sources, discovery failure/retry/cancel,
comparison/provenance, playback, editing/discard, recent/favorites, setlists,
settings persistence, file/package round trips, and PDF generation.

Harness repairs were necessary for the merged UI: replace legacy startup/grid
keys and the removed pitch-popup visibility choice; navigate Settings sections;
distinguish the library title from identical search-field text; wait for real
SQLite/navigation work; clear safe-area overrides instead of freezing portrait
insets; and use short scrolling gestures within the enlarged-text lyric
viewport. Failed runs and their screenshots are preserved, not counted as
passes. No production regression or production-code repair was established.

Native interactive coverage on both devices includes document/share/print
cancellation, exact original-song Files export/import, app song/setlist share
cancellation, backup export to local Files, merge-preview cancellation, merge
restore with preferences while retaining a newer song, replacement cancellation,
confirmed replacement, ChordPro import, setlist import, and repeat setlist import
without duplicates. No message, cloud upload, or print job was submitted.

The first iPad interactive run was interrupted after an operator coordinate tap
during the picker sheet transition failed to select the intended repeat-import
file. The UI returned to the existing library without the expected completion
event; no duplicate/import completion is inferred from that screen alone. Its completed backup assertions remain in the log. The isolated import
retry selected the settled picker, verified the import-success event and all
IDs/content/override assertions, and passed. This interruption is retained as
operator/test evidence, not an app failure or successful repeat-import result.

Verified runs:

| Device / scope | Evidence directory | Result |
| --- | --- | --- |
| iPad full combined suite | `ipad-full` | 14 passed, 1 Genius skip; 111 valid PNG checkpoints |
| iPhone final full combined suite | `iphone-complete` | 14 passed, 1 Genius skip; 111 valid PNG checkpoints |
| iPhone complete native layout matrix | `iphone-layout-v7` | Passed; 42 valid PNG checkpoints |
| iPhone native dialogs and Files/import | `iphone-interactive` | 3 passed; backup harness navigation failed and was rerun separately |
| iPhone app sharing and backup | `iphone-backup-v3` | Passed; 6 valid PNG checkpoints |
| iPad native dialogs and backup | `ipad-interactive` | 3 tests completed; interrupted during repeat import |
| iPad isolated native app imports | `ipad-import-retry` | Passed, including repeat import; final checkpoint recorded |

Fresh phone/tablet screenshots were reviewed across light/dark, portrait/
landscape, Ukrainian 150%, Arabic RTL 160%, reader/editor/settings/setlists,
and the added feature screens. No clear overlap or clipped essential controls
was found in the reviewed captures. At enlarged text, the phone Songs mode strip
scrolls horizontally; all four choices fit in the native iPad portrait capture.
A screenshot sample is not an exhaustive manual accessibility audit.

Live Unison HTTP and attributed Sean McGrath catalogue checks passed on both
devices. Genius was explicitly skipped because the build had no client access
token. The Android script reads it from an ignored local defines file, which
is absent on this Mac; GitHub variables and available build artifacts did not
provide it. User authorized reusing that Android app token, but its value/file
has not yet become accessible. Keep this an unverified live capability until a
configured native run passes. Google sign-in/Drive Picker/sync require the iOS
OAuth configuration and an authenticated account; only unavailable-state and
existing boundary coverage are established here. Physical hardware, real
VoiceOver interaction, cloud Files providers, and printer output remain outside
these simulator results.

Final analysis of all six modified test suites completed with no issues;
`git diff --check` passed. The final combined runs each passed 14 tests and
explicitly skipped the unconfigured Genius case. The four native workflow
tests per device passed across the recorded interactive runs and bounded
retries. Screenshots are native PNG checkpoints; `review-overview.jpg` is a
derived visual-review contact sheet, not a test result.


### Configured live provider follow-up — 2026-10-20

The owner supplied the existing Genius client access token. It was placed only
in ignored `config/local.defines.json`; the client secret is not used or saved.
The prior missing-token skips are superseded by these focused native checks:

| Device | Evidence | Result |
| --- | --- | --- |
| iPhone 17 Pro Max | `iphone-live-configured-v2` | 1 passed, no skips |
| iPad Air 13 | `ipad-live-configured` | 1 passed, no skips |

Genius returned a matching recording and usable lyrics on both. Seven live
sources contributed results, combined chords retained explicit contributor
provenance, and both timing tracks survived the ChordPro round trip. Other
providers' unavailable/import-required/identity-required/access-denied outcomes
remain explicit; this does not certify every source as healthy.

The initial configured iPhone run exposed an obsolete test assertion that the
selected lyric source itself must contain chords. Current combination can
merge a different chart into those lyrics. The assertion now requires recorded
chord contributors to resolve to non-rejected, chord-bearing source results.
The initial failure remains under `iphone-live-configured`; production code
was unchanged. Focused Dart analysis and `git diff --check` passed.


### Integration with current main — 2026-10-20

Before pushing the test branch, current public main `6ffba4b` was merged. It
advances the app to `0.2.9+23` and includes inline tab counts, setlist swipe
navigation, and timeline label measurement. The journey count assertion was
adapted to the inline labels. The native simulator results above remain tied
to `e6a15c7` (`0.2.8+22`); they do not claim a fresh full simulator run of
`0.2.9+23`. Focused merged-tree validation is recorded below.

Merged-tree validation: 57 focused UI/player/layout tests passed; displayed
version and User-Agent drift checks both passed; analysis of the parity,
journey, and provider integration suites reported no issues.


## Android release 23 parity — 2026-10-20

Base/current public main `af67a69`, application `0.2.9+23`, including Android
release commit `3702ae3`. Fetching the public repository found no newer main
updates at the start of this review. Actual diffs confirmed the new inline
counts, setlist swipes/transport boundaries and timeline font measurement are
shared Flutter code and already apply to iOS. No platform implementation gap
was found. Store version/build, profile and release guidance were stale and
are now aligned; historical verification records retain their original versions.

`ios_release23_device_test.dart` adds temporary-library native coverage for
single-line `Library(2)` counts, standalone-reader swipe no-op, left/right
setlist navigation across repeated songs with C/G key overrides, list
boundaries, and measured timeline label boxes using the real app font.
Portrait/light and landscape/dark Ukrainian at 150% and Arabic RTL at 160%
produce fresh native captures. The suite is included in the default full iOS
target; `ios_release23_validation_device_test.dart` also runs the store capture
suite. No original library or legacy app data is used.

Evidence: ignored `artifacts/ios-release23-20261020/`. Initial paired runs
`iphone-v2` and `ipad` each passed both store capture and release-interaction
tests (seven valid PNG checkpoints). The first phone run failed only because
the test compared English marker names to Ukrainian semantics; the corrected
comparison uses localized section names. Later focused runs add Arabic RTL and
control-heading reachability without changing the application. The large-text
control panel initially anchors to its bottom and may show only part of the
upper current-section heading; scrolling reveals it fully. This is explicitly
checked rather than claiming all controls are visible simultaneously.

All eight App Store screenshots were refreshed at native resolution and
reviewed; two unchanged setlist images are byte-identical. Source/RGB hashes
were updated and the offline store validator passed for `0.2.9+23`. The new
unsigned archive built successfully; privacy inspection found 18 manifests,
minimum iOS 15.0, correct bundle ID and version/build. The prior archive is
preserved, and `archive-record.json` records the source and binary hash.
No fresh full-app e2e run is claimed here: these are focused release-delta
checks on top of the preceding full-app and configured live-provider results.


Final focused release checks: `iphone-final` and `ipad-final-v2` each passed
one test with five valid native captures, including the complete Arabic
control-heading reveal. The initial tablet reveal assertion also matched the
lyric heading; it was scoped to the seek-control column and rerun successfully.
Analysis of the release, validation wrapper and default full target reported
no issues. Store validation and whitespace checks passed. Signing, physical
hardware and authenticated Google Drive remain outside this verification.

The displayed-version and User-Agent drift checks both passed for `0.2.9+23`.
All temporary build/device reservations were released after verification.

The account UI exposes visible Drive folder selection and ChordPro import on iOS using the existing account-bound system-browser Picker. Its OAuth flow uses the documented [desktop/mobile Google Picker](https://developers.google.com/workspace/drive/picker/guides/desktop-mobile-picker) with `drive.file`, PKCE and state validation. Live sign-in and folder migration require a dedicated QA account and are separate from deterministic fixture coverage.

For headless native runs, `SINGBOOK_NATIVE_SESSION` enables an app-support JSON receipt containing the integration binding's actual outcomes, failures, platform and physical dimensions. Session names must use letters, digits, underscores or hyphens. A receipt must contain the expected tests and `allTestsPassed: true`; missing, skipped or failed tests are not a successful native run. Normal `flutter test` execution remains supported.

## Release 45 parity candidate — 2026-10-29

The combined native suite built from `d2befd7c63fb440260466ee84b53b59b54fe33d0`
(`0.2.31+45`) passed 15/15 cases on iPhone and 13/15 on iPad, using the same
compiled test app and isolated libraries. The runs produced 96 and 58 fresh
captures respectively. Ignored evidence is under
`artifacts/ios42-parity/combined45-native-phone01/` and
`artifacts/ios42-parity/combined45-native-tablet01/`; each includes the actual
binding results and a native receipt. The two iPad failures are the fullscreen
orientation and native layout rotation cases: the physical window stayed
portrait after programmatic orientation requests. These failures remain open;
the documented host-controlled rotation route must be exercised without
disabling iPad multitasking or substituting a logical viewport resize.

The new channel-9 coverage exercises Chords & Tabs through search, comparison,
Save and reader UI, then closes and reopens SQLite to verify persistence and
ChordPro provenance. OpenScore is explicitly checked as disabled by default;
its direct provider fixture verifies persistence and rights metadata, without
claiming ordinary UI availability. These use synthetic responses and original
fictional lyrics, not live-provider or authenticated account checks.

Head `948847a74ca208e0e1800dc41c679a32e2cdb8a1` changes only the macOS
architecture verifier relative to that native source. Product and native-test
blob equivalence is recorded in
`artifacts/ios42-parity/macos-verifier-repair01/source-equivalence.json`.
Its macOS compilation run `40787342230` and UX validation run `40787339058`
passed. CI run `40787336232` failed: the Linux bounded-phrase test took
3.395 seconds against its unchanged 3-second bound, and Windows test shards
stopped before tests because `jq` was missing. Passing UX does not supersede
those failures.

An additional unsigned iOS Release compile at that head passed; its static
qualification found 18 privacy manifests and excluded the debug clipboard
reader. Evidence is under `artifacts/ios42-parity/release-config-compile01/`.
This is compile qualification, not a new signed distribution artifact or runtime
result. Native OS picker/share/backup interaction and authenticated Google Drive
and iCloud scenarios remain unverified for this candidate. The changes are not
included in the preserved signed release-45 artifact, and no store action is
implied by these results.
