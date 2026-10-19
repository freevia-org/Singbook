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
| `singbook_journey_device_test.dart` | Fixture-provider search, failure/retry, comparison and provenance, save/edit, favorite, player and timing, setlist operations, settings/reload, ChordPro and collection-package round trips, PDF generation. Import bytes enter the public controller API; this does not operate the OS document picker. |
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
