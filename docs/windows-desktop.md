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

### Current automated and native evidence — 2026-10-21

PR #93 head `71cb5a80862dfba7b65a2070f8c3d0bb9b398ec5` passed both jobs in
[CI run 39653863257](https://github.com/freevia-org/Singbook/actions/runs/39653863257).
Linux localization verification, analysis and the full Flutter suite passed.
Windows passed Desktop OAuth configuration preflight, release packaging,
isolated portable startup and graceful close, native clipboard and Credential
Manager checks, and the full Flutter suite. The OAuth preflight reached Google's
expected invalid-code response; it confirms configured Desktop OAuth values,
not a fresh sign-in or the complete Drive lifecycle. The clipboard check sends
`WM_PASTE` to a hidden native edit control and verifies Unicode plain text; it
does not prove formatted paste into another application.

The run's portable package is version `0.2.12+26`, built from synthetic PR
merge commit `16b4c9ab088019ed8163ca043244df2c854dd159` with PR head
`71cb5a80862dfba7b65a2070f8c3d0bb9b398ec5`, ZIP SHA-256
`7DA14D0FF43D14B98883EC458A5800E8F7ECB3ACE8F2E92ACE0E0EDF107F40AB`.
The downloaded archive was checked against its manifest: all 54 files were
present and all hashes matched. The package embeds the configured Desktop
OAuth client ID and secret. Source-layout captures also
cover desktop library, setlists, reader, editor, settings, dark mode and
compact/large-text variants. Those widget captures do not establish the full
packaged native size, DPI, theme and localization matrix.

The broader scripted Sandbox workflows used the packaged build from CI run
39642446550 (ZIP SHA-256
`D439E3BADCBE30D9FB468E55EA26A473D121616B7F6C5CC280CB5A87E9654AB8`), whose
runtime source was the implementation head above. The later PR update contained
documentation and screenshots only; CI run 39647967822 also rebuilt and
smoke-checked the current package. Sandbox testing ran at 144 DPI on a
2048×1232 display with fresh disposable database paths and no Drive sign-in.
Native screenshots and summaries are held in the
run-specific evidence folders below `E:\acceptance\Singbook-native-819278c2\`:
`final-evidence`, `restore-evidence`, `restore-apply-evidence`,
`setlist-add2-evidence`, `setlist-reopen-evidence`, and `setlist-export-evidence`.
It verified app
startup, native `.cho` import, cancellation of a second import, reader
navigation, readable untruncated timeline labels (Intro, Verse 1, Chorus,
Verse 2, Chorus and Outro), account-and-sync layout, native backup Save As, and
backup preview showing one song and zero conflicts. The exported
`.lyrics-setlist` archive passed ZIP integrity checks and contains the synthetic
fixture. The app closed gracefully; the temporary database contains only that
fixture. A second clean disposable database accepted the exported backup in
the native restore flow; a direct SQLite check found exactly the synthetic song
and no setlists, and the app closed gracefully. The native setlist flow created
a list, added the fixture, then showed the saved one-song, 1:30 setlist after a
fresh app launch; SQLite confirmed one song, one setlist and one setlist entry.
Native `.osts` export produced well-formed OpenSong XML with the synthetic
song, PDF export produced a readable two-page PDF, and Print opened the Windows
Print Setup dialog and closed on cancel. A dirty-editor close test showed the
native discard prompt, confirmed cancel kept the editor open, saved the edited
synthetic title, then reopened the same database after a full app restart and
confirmed the saved title persisted. This test used the same prior packaged
build and a disposable database; evidence is in `editor-close-evidence`.
Setlist editing and reorder persistence remain unverified.

Representative exact-package native screenshots are committed for review:
[reader and timeline](images/windows-desktop-review/packaged-20261021/reader-144dpi.png),
[setlist after restart](images/windows-desktop-review/packaged-20261021/setlists-after-restart.png),
[account settings](images/windows-desktop-review/packaged-20261021/account-144dpi.png),
[backup Save As](images/windows-desktop-review/packaged-20261021/backup-save-as.png),
[restore preview](images/windows-desktop-review/packaged-20261021/restore-preview.png),
and [Windows Print Setup](images/windows-desktop-review/packaged-20261021/print-setup.png).
At this desktop size the reader's lyrics column and playback rail are centered
within the app frame, timeline labels remain legible, and account cards stay
aligned; this visual review does not substitute for the unrun resolution, DPI,
theme and locale matrix.

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

Automated Windows tests additionally cover Unicode export filenames, ChordPro
and song/setlist PDF bytes, Save As cancellation and errors, setlist drag and
accessibility reorder behavior, player preference persistence, Windows HTTP
103/redirect/concurrency behavior, and database/startup path handling. These
checks establish the application logic and platform adapters; they do not
exercise every native dialog or interaction in the packaged app.

Remaining packaged-native checks include Unicode Save As paths and overwrite
behavior; ChordPro and song-PDF Save As round trips; setlist edit/reorder
persistence after a fresh restart; player mouse/keyboard interactions and
preference persistence after restart; printing to a saved PDF; formatted paste
into another application; and
representative provider workflows. The full packaged locale/theme/DPI and
compact/large-screen matrix also remains. The user confirmed that their
existing library synced successfully in a previous `0.2.12+26` interactive
session; no synthetic song was uploaded. Token refresh, offline recovery,
revoked-grant handling and sign-out still need lifecycle acceptance. The
current portable bundle passed CI startup smoke, and the native Sandbox run
verified selected workflows on the packaged build, but no separate clean
machine installation test was performed. PR #93 remains Draft; keep the release
in review until the required acceptance rows are passed or explicitly waived.

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
