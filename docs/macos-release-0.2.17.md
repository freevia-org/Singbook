# macOS 0.2.17 (31) direct-download release

The universal macOS candidate uses the full desktop window instead of the
1,200-pixel tablet frame. Native Cocoa Command-S handling also preserves the
per-event Command modifier that Flutter can lose for synthetic keyboard input.
Mobile/web tablet widths and the physical-keyboard Flutter fallback remain.

Binary source: `b08d285d`, based on public main `0a40d7f`. The later editor
source change only adds braces around an existing conditional for lint; it
does not change the compiled behavior. Subsequent repository-only changes
ignore host-generated plugin registration and correct the CI lipo invocation. The build script recorded a clean
source state before compiling. Existing build 30 and its verified artifacts
were preserved; it remains the separate App Store review submission with
automatic release after approval.

## Validation

- Focused desktop width/parity, tablet, displayed-version and transport checks:
  29 passed. Localization and User-Agent/version checks: 31 passed.
- Updated desktop/native-save/modal regression checks: 9 passed.
- Final source analysis: no issues.
- Native sandbox integration: 3 passed, including real HTTPS, disposable
  Keychain entries, SQLite close/reopen with preserved ID/body, and PDF raster.
- Native-renderer profiles reviewed at 1920×1080 and 1280×800 English light,
  800×600 Ukrainian dark/150%, and 390×720 Arabic RTL dark/160%.
  The actual signed release was also zoomed to the 2560-pixel desktop width;
  library, header and controls fill the window without the outer side bands.
- XCUITest against the signed release export passed the native Command-S save
  and return-to-reader check using real application key events. Test harness,
  original diagnostic failures and final result are retained under ignored
  `artifacts/macos-acceptance/release31/`; final result is
  `release-command-save.xcresult`.
- Native accessibility checks verified Space play/pause and both unsaved-close
  choices on the exact candidate. Keep Editing canceled close; Discard exited
  without saving the disposable draft. Native Command-Q also exited cleanly.
- Native Open import and cancellation, Save As export and cancellation, and
  system print cancellation were exercised using the original Lanterns fixture.
  The exported ChordPro retains lyrics and the `x_verse` payload. A consistent
  SQLite backup was taken before the update; normal launch preserved song IDs,
  content hashes and documents. Only this session's disposable QA fixture was
  edited during keyboard checks, then its title was restored.
- Xcode RunnerTests identity/category/privacy/localization check passed after
  correcting the local test bundle's ad-hoc signing to match its development
  signed host. That signing repair affects only the ignored test host.

The native-control API and XCTest modifier flags alone do not update Flutter's
HardwareKeyboard state (see Flutter issue 178609). The diagnostic probe showed
this explicitly. Cocoa Command-S now works through both automation paths.
XCTest physical clicks on the red close button intersect the macOS window-
sharing overlay, so close assertions use native accessibility actions instead.

## Distribution status and caveats

The final candidate archive/export is under ignored local directory
`artifacts/macos/20261023T073342Z-b08d285d-49381/`.
It has Developer ID signing, hardened runtime, sandboxing, macOS 12 deployment
and both arm64/x86_64 slices. Apple accepted notarization. The exported app and
a fresh ZIP extraction passed deep/strict signature checks, stapled-ticket
validation and Gatekeeper assessment (`Notarized Developer ID`). The fresh
extraction was quarantined, launched through App Translocation, opened the
preserved QA library and quit cleanly. Public download reproduced the checksum.

Published release: [macos-v0.2.17](https://github.com/freevia-org/Singbook/releases/tag/macos-v0.2.17).
[Direct download](https://github.com/freevia-org/Singbook/releases/download/macos-v0.2.17/Singbook-0.2.17-macos-universal.zip). SHA-256:
`b2d343197214a1335c7e546a869059b9aef2a0b505bfb7a63deae2536a8bbde9` (34,758,028 bytes). The release tag is exact source/CI freeze
`3ef30783e3eea113e6cd96a9e349ffd4e2383ea4`; all check, Windows build/full-suite,
and hosted unsigned universal-macOS compilation checks passed. No PR merge or
rebase was performed. PR #105 remains the integration proposal. The exact
release/asset/checksum and coverage caveats were sent to the Website session
at the owner's request.

Testing used the available Apple Silicon Mac. Physical Intel hardware,
macOS 12 runtime and a separate pristine Mac/user account were unavailable;
those configurations must not be described as runtime-tested. The available host passed the fresh extracted
package/Gatekeeper/cold-launch check.
Google Drive sync and Genius are unavailable because this build has no Google
OAuth client or Genius token. No preloaded song catalogue is included. Saved
libraries work offline; enabled external sources require network access and
can vary by region or service.

The bundled source catalog is revision 5 on public base `0a40d7f`; later
Android/Windows PR #102 source-coverage changes are not in this macOS snapshot.
Use this exact macOS asset URL instead of a cross-platform latest-release URL.
No device/build directory remains reserved and no Flutter/Xcode test or
notarization process from this session remains running. Verified originals,
failed-attempt evidence and signing material remain local and ignored.
