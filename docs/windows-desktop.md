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
runtime DLLs and `data/` directory beside it. The manual Windows CI job compiles
this release bundle on the dedicated `singbook-i5-windows` runner. Its required
runtime/asset manifest and ZIP are preserved as a workflow artifact. Source-only
packaging changes still need a successful release build and extracted-bundle
acceptance.

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

### Current automated and native evidence — 2026-10-22

The current Windows candidate is Singbook `0.2.14+28` from PR #97 head
`c933c0a54e88498464803a8889b0f8af1cccda50`. The branch is clean, the PR is
open as a draft, and GitHub reports it mergeable. CI run
[39777236285](https://github.com/freevia-org/Singbook/actions/runs/39777236285)
passed Linux localization generation, analysis and the full Flutter suite, and
Windows OAuth preflight, release packaging, isolated portable startup/graceful
close, native clipboard and Credential Manager checks, the full Flutter suite,
and the deterministic desktop journey. The OAuth enforcement step was skipped
because preflight succeeded. The downloaded portable ZIP SHA-256 is
`56301A61E61219C912673267250736920BF79827520319BFA6064FF20837804A`; all 54
runtime-file hashes match the downloaded package, and the executable SHA-256 is
`FF49E17772FCB4D6EF74CB53829A1C48D9F92BEB6D447C31B19374C51A868D9B`.

The submitted unsigned Store MSIX was built from Windows release bundle
artifact `12421818168` in CI run
[39769176975](https://github.com/freevia-org/Singbook/actions/runs/39769176975),
at source commit `b54a863c7d8443ada08c64b31840fda88f16e621`. Packaging workflow
[39771768067](https://github.com/freevia-org/Singbook/actions/runs/39771768067)
created artifact `12422577924`; its package SHA-256 is
`474ED2C686A8A1F1D8633DD56B12AC1F192528631D2EEC7DEB1C51B0EEE0DE89`. Hosted
MSIX smoke run
[39777236298](https://github.com/freevia-org/Singbook/actions/runs/39777236298)
installed, launched, closed, and reopened that exact unchanged package. It
verified package identity and image path, isolated database persistence across
restart, and graceful close. The package has since been submitted to Microsoft
Store certification; certification and publication are still pending. The
submission does not establish full native parity. The source difference from
`b54a863` to PR #97 head `c933c0a` contains only Store packaging and hosted
install-test workflow/helper files; the app runtime and UI are unchanged.

Current CI layout captures include 1920×1080 desktop reader, setlists, settings
and Ukrainian settings, plus tablet landscape and portrait layouts. A separate
read-only visual review found no actionable alignment, clipping, or density
defects: desktop timeline labels are fully visible, setlist and settings content
is centered consistently, and tablet spacing remains readable. The native
startup image for the submitted MSIX is 1040×736 and shows the Songs screen.
These captures do not prove the complete packaged locale/theme/DPI matrix.

An earlier PR-head CI run, [39668863757](https://github.com/freevia-org/Singbook/actions/runs/39668863757), passed on `673869eb4c3ffebd17deef452af1ee16f7ad00da`. Linux localization verification, analysis and the full Flutter suite passed. Windows OAuth preflight, release packaging, isolated portable startup and graceful close, native clipboard and Credential Manager checks, and the full Flutter suite passed. The OAuth release-enforcement step was skipped because its preflight dependency succeeded. The run preserved `windows-release-bundle` and `windows-validation-evidence`; the bundle artifact digest is `sha256:06ddd57bdb6c3e6a3411c0409581e4041b00f77fd1f7910d390fd86ae1a7809f` (the digest is for the enclosing GitHub artifact, not the portable ZIP inside it). These checks verify that earlier PR head's build and automated behavior, but do not close the native UI acceptance gaps listed below.

PR #93 head `fd5d77babc6bc8317e058f8a390d154c830c9fbb` passed both jobs in
[CI run 39657693802](https://github.com/freevia-org/Singbook/actions/runs/39657693802).
Linux localization verification, analysis and the full Flutter suite passed.
Windows passed Desktop OAuth configuration preflight, release packaging,
isolated portable startup and graceful close, native clipboard and Credential
Manager checks, and the full Flutter suite. The OAuth preflight reached Google's
expected invalid-code response; it confirms configured Desktop OAuth values,
not a fresh sign-in or the complete Drive lifecycle. The clipboard check sends
`WM_PASTE` to a hidden native edit control and verifies Unicode plain text; it
does not prove formatted paste into another application.

The run's portable package is version `0.2.12+26`, built from synthetic PR
merge commit `dba0f64aa4f39d3e0a3ce500ff181d64671ac72f` with PR head
`fd5d77babc6bc8317e058f8a390d154c830c9fbb`, ZIP SHA-256
`C63ADD111A7F6809FBF4FB00F38CA3CE25B0ABBAE0DF5263096AEB142D6C9E45`.
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

The follow-up print-to-PDF attempt did not produce a saved file. Sandbox
inspection confirmed `Printing-PrintToPDFServices-Features` is
`DisabledWithPayloadRemoved`; every available printer is redirected through
Remote Desktop Easy Print, including “Microsoft Print to PDF (redirected 1).”
This explains the missing local save dialog but does not count as a successful
print acceptance.

Setlist edit and mouse reorder were then verified using a disposable two-song
database. The first row was dragged below the second, the setlist was renamed
through the inline editor, and after full restart both the new title and row
order were visible in the setlist card and SQLite. Screenshots and run summary
are in `setlist-edit-evidence` and `setlist-edit-final-evidence`.
The exact portable ZIP from CI run 39657693802 (SHA-256
`C63ADD111A7F6809FBF4FB00F38CA3CE25B0ABBAE0DF5263096AEB142D6C9E45`) also
passed packaged ChordPro and song-PDF Save As checks. Both files were saved
through the Windows dialog into a Unicode directory (`Пісні QA`); ChordPro
content, PDF signature and size, and graceful app shutdown were verified. The
run summary and dialog screenshots are in
`E:\acceptance\Singbook-native-819278c2\song-export-uia-evidence`, and the
outputs are in `E:\acceptance\Singbook-native-819278c2\exports\Пісні QA`.
Packaged player checks in `E:\acceptance\Singbook-native-819278c2\player-ui-evidence`
verified mouse Play, Space pause/resume, next-section navigation and persistent
settings. After disabling chords and section headings, closing and reopening the
app preserved both settings; the reader hid chords while retaining the full
timeline. Reinspection of the packaged Settings screenshots confirms the preview
also hides its sample chord labels and section heading when both switches are
off. The live preview widget test covers changing both switches without leaving
Settings. Screenshots and summary are in `player-ui-evidence` and
`player-state-check-evidence`.

Representative exact-package native screenshots are committed for review:
[reader and timeline](images/windows-desktop-review/packaged-20261021/reader-144dpi.png),
[setlist after restart](images/windows-desktop-review/packaged-20261021/setlists-after-restart.png),
[account settings](images/windows-desktop-review/packaged-20261021/account-144dpi.png),
[backup Save As](images/windows-desktop-review/packaged-20261021/backup-save-as.png),
[restore preview](images/windows-desktop-review/packaged-20261021/restore-preview.png),
and [Windows Print Setup](images/windows-desktop-review/packaged-20261021/print-setup.png).
At this desktop size the reader's lyrics column and playback rail are centered
within the app frame, timeline labels remain legible, and account cards stay
aligned. A fresh exact-package Sandbox review at 1024×720 confirms the Songs
library remains legible and aligned in a compact desktop window: [library at
1024×720](images/windows-desktop-review/packaged-20261021/library-1024x720.png).
The 1280×800 Sandbox matrix also covers library, setlists, and reader. This
review does not substitute for the remaining DPI, theme, and locale matrix.

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

Earlier verified package candidate before the Windows live-smoke helper update:
PR #93 head `868bee9cf2740ee8fef39ba2911cfaf7c988dd2d` (PR #93 has since been
merged; this earlier candidate is superseded by the current build above).
CI run [39675132042](https://github.com/freevia-org/Singbook/actions/runs/39675132042)
passed both Linux and Windows jobs on that PR head. Windows OAuth preflight,
release packaging, isolated portable startup and graceful close, native
clipboard and Credential Manager checks, and the full Flutter suite passed.
The release-enforcement step was skipped because OAuth preflight succeeded.
The run produced a version `0.2.12+26` portable ZIP with SHA-256
`C2416218C96954958EB164EBDEAB87F0ACB6F4AFF1D8BF5BAF99FB60272ABB3B`.
Its manifest identifies source commit `f12501a85098281a9dec5abe2beb15eafce79d2d`
and source tree `420923c412fb7b02d3bb643aa1851905e5d53f8e`; all 54 packaged
file hashes and 50 required-file entries were verified from the downloaded CI
artifact. OAuth configuration is present (only presence flags are recorded).

The current large-screen widget captures remain source-current: production UI
code has not changed since commit `819278c`. A read-only review of the 1920×1080
English/Ukrainian light/dark library, setlists, reader, editor, home and account
captures found no actionable alignment or clipping defect. This is source/widget
evidence, not packaged Windows DPI/font-scaling proof.

The exact Store candidate is in certification. Full packaged native parity is
still incomplete; the following broader acceptance items remain follow-up and
must not be represented as verified:

| Gate | Current evidence | Status |
| --- | --- | --- |
| Portable package build and automated Windows suite | CI run 39777236285; 54/54 packaged file hashes verified. | Passed |
| Store package installation and restart | Exact submitted MSIX; hosted smoke run 39777236298. | Passed for hosted smoke |
| Large-screen visual alignment | 1920×1080 CI captures and read-only review; no visible clipping or alignment defects. | Passed for reviewed captures |
| Packaged locale/theme/DPI and compact/large layout matrix | Submitted package screenshot covers one 1040×736 Songs screen. | Follow-up |
| Print to a saved PDF from the packaged UI | Older Sandbox check opened Print Setup, but did not save a PDF; hosted runner flow not yet exercised. | Follow-up |
| Formatted paste into another application | Clipboard format and plain-text paste are tested; rich paste rendering in a receiving app is unverified. | Follow-up |
| Packaged provider search-to-open workflow | Current-source provider transport smoke ran, but not through packaged UI. | Follow-up |
| OAuth lifecycle on the current package | Prior `0.2.12+26` same-account sync succeeded; current-package refresh, offline recovery, revoked grant and sign-out were not exercised. | Follow-up |
| Distribution | Submitted to Store certification; automatic publication is pending certification. | In certification |

An opt-in public-provider smoke run on 2026-10-22,
rerun against the current source, used `WindowsHttpClient` directly (the
`dart run` conditional import otherwise selects a fallback client): Worship
Commons, Sean McGrath Music, Open Filk
Songbook and Chordie returned lyric results; MusicBrainz returned catalog rows
without lyrics; Wikidata and Wikisource returned HTTP 403. The probe exited 0
and logged provider IDs, result titles, counts, body lengths, chord/timing flags
and metadata keys, not lyrics or credentials. Current-source output and run
metadata are in `artifacts/windows-parity/current-live-smoke-20261022T070617966/`.
This is partial provider/transport evidence, not packaged UI acceptance or a
pass for providers returning 403. The user confirmed that their
existing library synced successfully in a previous `0.2.12+26` interactive
session; no synthetic song was uploaded. Token refresh, offline recovery,
revoked-grant handling and sign-out still need lifecycle acceptance. This turn
used CI, repository and command-line provider evidence only; no Sandbox was
used. Installer, SmartScreen and antivirus behavior are not applicable to the
portable ZIP workflow and were not assessed. PR #93 has been merged; no Windows
GitHub Release has been published. The CI artifact is temporary, so a permanent
distribution step remains separate from acceptance.

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
