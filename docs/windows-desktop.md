# Windows desktop preview

Singbook uses the existing Flutter app and song/library formats on Windows.
The Windows runner is generated from Flutter's standard desktop template. The
local SQLite backend uses `sqflite_common_ffi`; its database lives below the
per-user application-support directory as `databases/verse_library.db`.
This backend and path selection apply only to Windows. Existing Android, iOS,
macOS and Linux database factories and default paths are preserved.

## Development

Use Flutter 3.44.8 and Visual Studio 2022 with the **Desktop development with
C++** workload and Windows 10 SDK. From the repository root:

```powershell
flutter pub get
flutter run -d windows
```

To build a local debug bundle:

```powershell
flutter build windows --debug
```

For a traceable portable bundle, commit the source and run
`pwsh scripts/build-windows.ps1`. Supply the build configuration in the ignored
`config/local.defines.json`; `-AllowMissingDefines` explicitly permits an
offline preview. `-Debug` selects a debug bundle. Every run writes a unique
directory under `artifacts/windows/` with the build log, ZIP, source commit/tree
and SHA-256 manifest. Release builds include the compiler's redistributable
Microsoft C++ runtime DLLs next to the executable. Packaging checks the copied
engine, AOT, assets, native SQLite, PDFium, plugin DLLs and release runtimes before
creating the ZIP. Debug bundles are for local development and require developer
runtimes. Keep the entire extracted `Singbook` directory together.
Packaging alone does not establish clean-machine runtime acceptance.

The executable is under `build/windows/x64/runner/Debug/` with Flutter's
runtime DLLs and `data/` directory beside it. The Windows CI job compiles this
release bundle on `windows-latest`. Its required runtime/asset manifest and ZIP
are preserved as a workflow artifact. Source-only packaging changes still need a
successful release build and extracted-bundle acceptance.

## Current scope

Windows exports use a native Save As dialog for ChordPro songs, OpenSong
setlists, PDF and library backups. Other platforms retain native sharing.
The Windows runner provides both Unicode plain text and Windows HTML Format
for formatted copy, and current-user Credential Manager storage for OAuth.
The editor participates in Flutter's cancelable window-exit request so closing
a changed draft can be canceled.

Recorded automated checks and remaining native acceptance are listed below.
These additions are not yet a claim of full parity. Use the repeatable workflow
in [Windows acceptance](windows-acceptance.md) for the native run.

## Google Drive configuration

Create an OAuth client of type **Desktop app** in the **same Google Cloud
project** as the Android/iOS clients, with Drive API and Google Picker API
enabled. Do not use the
Android or Web client ID for the desktop loopback flow. Copy its identifier to
`SINGBOOK_GOOGLE_DESKTOP_CLIENT_ID` in the ignored build configuration. If the
downloaded desktop registration requires its generated client secret, put it in
`SINGBOOK_GOOGLE_DESKTOP_CLIENT_SECRET`. For GitHub Actions builds, configure the
ID as the `SINGBOOK_GOOGLE_DESKTOP_CLIENT_ID` Actions variable and, only when the
registration requires it, configure the secret as the
`SINGBOOK_GOOGLE_DESKTOP_CLIENT_SECRET` Actions secret. The Windows package embeds
any configured value, so it is not confidential once distributed. Do not put
the downloaded JSON or tokens in Git or validation logs. Desktop registrations
are public clients; PKCE is still required even when a registration has this
field.

The desktop module opens the system browser, validates a random state value at
an ephemeral IPv4 loopback callback, exchanges an S256 PKCE code, obtains the
account identity from Google's HTTPS user-info endpoint, and keeps refresh
tokens in the Windows vault. Only an explicit account action starts this flow.
The desktop client must be configured before real sign-in/refresh/Drive acceptance
can be completed. The shared sync service selects desktop authorization on Windows
and retains mobile authorization on Android and iOS. Visible-folder access uses
the same primary account with a separate, narrow `drive.file` authorization.

Folder selection and ChordPro imports use Google's native desktop Picker in a
separate browser authorization containing only `drive.file`. Selected IDs are
accepted only after Drive's account details match the connected account. Its
refresh grant is stored separately per desktop client and account; sign-out or
account switching removes the previous account's grant. Cancellation keeps a
previously usable grant. Normal sign-in and background sync never open a Picker
or add this scope automatically. No hosted Picker page or browser API key is
required for this native flow.

References: [Google desktop OAuth](https://developers.google.com/identity/protocols/oauth2/native-app)
and [native desktop/mobile Picker](https://developers.google.com/workspace/drive/picker/guides/desktop-mobile-picker).

## Acceptance evidence

Use a disposable test library for native workflow checks. Preserve the logs,
screenshots and source manifest together; never replace a user's library or
clipboard for an unattended check.

| Area | Required evidence |
| --- | --- |
| Storage | Default Windows factory/path, close/reopen songs and settings, complete app restart, existing non-Windows paths preserved. |
| Files | Native import and Save As, Unicode paths, cancel/overwrite, round-trip songs, setlists, PDFs and full backups. |
| Player | Section timing including instrumental sections; mouse seeking, skip, speed, transpose/None, highlighting and persisted preferences. |
| Desktop input | Keyboard controls while typing and in menus; mouse whole-row setlist reorder/delete; changed-editor close/cancel/discard. |
| Clipboard | UTF-8 CF_HTML offsets and UTF-16 conversion, real formatted paste and plain-text fallback. |
| Credentials | Isolated synthetic vault entry lifecycle, real sign-in, restart, refresh, offline failure, revoked grant and sign-out. |
| Network | Windows default client with HTTP 103/final responses, redirects and concurrent requests; representative provider workflows. |
| Print/links | Windows print/save-to-PDF/cancel and external-browser launch. |
| Layout | Native screenshots at compact/desktop sizes, large text, DPI changes, themes and RTL. |
| Delivery | Release bundle extracted outside checkout, dependencies present and clean-machine launch. |

### Current automated evidence — 2026-10-21

PR #93 head `1190b2f746bf98af6d621342f4c9ff8054c375c3` passed both jobs in
[CI run 39627883980](https://github.com/freevia-org/Singbook/actions/runs/39627883980).
The Windows job passed release packaging, OAuth configuration preflight,
isolated portable startup and graceful close, native clipboard and credential
checks, and the full Flutter suite. The Linux analysis and test job also passed.
The clipboard check sends `WM_PASTE` to a hidden native edit control and verifies
exact Unicode plain text; it does not prove formatted paste into another
application. The OAuth preflight reached Google's expected invalid-code response
and the bundle reports both Desktop OAuth values configured; it does not prove a
fresh user sign-in or the full Drive lifecycle.

The portable release is version `0.2.12+26`, built from PR merge commit
`8358e63ae06dbb83de4a404603a81a61debfd5f3` and source tree
`08208f158e0d7563c9cd71964240b39149ad8c40`, ZIP SHA-256
`3B8113A6734B3A923C57A1A50EC946B58B9DE8D3E7B5E4FE9352DC8A65239C5D`.
Its manifest lists 54 bundled files, including 50 required runtime files. The startup smoke produced a
valid SQLite database, observed the `Singbook` main window, captured its pixels,
and closed the app gracefully without a forced stop. The packaged screenshot is
[available here](images/windows-desktop-review/packaged-startup.png); it is a
review crop from CI run 39622130652. The raw 1044×720 BMP for that image remains
in that run's validation artifact; the committed PNG crops the unpainted 8-pixel
left and bottom margins. Run 39627883980 also captured the current package's
startup window in its validation artifact. I reviewed that capture: the app
content shows a centered empty-state message, aligned search and category tabs,
and no visible clipping. These captures do not cover the complete native size,
DPI, theme, and localization matrix.

Source-layout captures also cover desktop library, setlists, reader, editor,
settings, dark mode, and compact/large-text variants. Four representative
captures are committed for review: [library](images/windows-desktop-review/library.png),
[setlists](images/windows-desktop-review/setlists.png),
[reader](images/windows-desktop-review/reader.png), and
[editor](images/windows-desktop-review/editor.png). The library uses a balanced
three-column grid, and the reader and setlist content stay centered with no
visible clipping. Short landscape comparison previews now use denser spacing;
the `native-shaped short landscape shows chords and match above Save` regression
test covers a 2.625× device scale with safe-area insets. The full affected UI test
file passes locally.

These checks establish automated build, startup, screenshot, and source-layout
evidence, not full native acceptance. The native file-dialog/import-export,
print-dialog, cross-application formatted-paste, and packaged interaction-
persistence checks remain unrecorded. Real account authentication and the full
Drive lifecycle also remain separate acceptance items. Keep the release in
review until the required rows above are passed or explicitly waived.

The frozen `e0e14a1` source passed both jobs in
[CI run 39237237228](https://github.com/freevia-org/Singbook/actions/runs/39237237228):
analysis/full tests on Linux, Windows debug compilation, isolated native helper
checks and focused Windows regression tests. This predates the native Picker
follow-up and does not establish real account, GUI or release-bundle acceptance.

The native Picker follow-up passed 45 focused primary/file authorization and
loopback tests plus targeted analysis of the six changed Dart source/test files.
Responses from Google and the vault were mocked; callbacks used real loopback
HTTP. Evidence is under `artifacts/windows-parity/picker-20261019/`, including
the initial record-type compile failure, its correction and passing retry.

`pwsh scripts/test-windows-native.ps1` compiles and runs pure native helper
checks. `-CredentialStore` also creates one unique synthetic vault entry and
verifies deletion; it never enumerates existing credentials. The script never
writes to the clipboard. Native checks save exact command/output in a unique
`artifacts/windows-parity/native-*/` directory.
