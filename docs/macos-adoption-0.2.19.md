# macOS 0.2.19 (33): source review gate

This is source preparation, not a tested, signed, submitted or published release.
The published Mac 0.2.17 package and Store 0.2.16 submission remain separate.

## Composition

- Common candidate: `9ec6b29504a380531dc38db6f8beed98a9f55195`, tree
  `315bf164f7d657e853804d0c184cb395a2e9f5b5`, version 0.2.19+33.
- Native transfer parent: `0835d079d3fc8ffb8dc84eb55947f0921b962aea`, PR #115.
- Reconciled narrow editor/player/setlist hunks come from accepted Mac source
  `880ae548778f1513aa0b18876dd64e251a75c7d6`, without copying those whole files.
  Current shared editor validation, player behavior and setlist changes remain.
- Native Cocoa Command-S bridge is restored with the editor's current-route
  guard and existing serialized save. Control-S alone remains inactive on Mac.
- Full-width desktop layout already exists in the common candidate. It is
  preserved without changing the current reader/phone/tablet layout rules.
- Provider directory, source catalog, README and four release version files
  remain byte-identical to the common candidate. No old provider/version blobs
  were adopted. No iOS file is changed.
- Both native SwiftPM lockfiles retain blob
  `50fa625af892c05b693411470d782c4c992097ac`, identical to accepted Mac source:
  GoogleSignIn 9.2.0, AppAuth 2.1.0, AppCheck 11.3.2, GoogleUtilities 8.1.5,
  GTMSessionFetcher 3.5.0, GTMAppAuth 5.0.0, interop 101.0.0, Promises 2.4.1.
  These are source pins; fresh dependency resolution/compilation is not claimed.

## Privacy and signing review

The Mac app manifest now has the same semantic declarations as current iOS:
linked Search History for App Functionality, no tracking or tracking domains,
and File Timestamp required-reason C617.1. Other User Content was an extra Mac
declaration in the transferred snapshot. Its removal is conditioned on Google Drive remaining disabled. Mac 33 uses
the existing approved Genius private input; Genius search is covered by the
existing Search History declaration. No new token is created. The existing
private file is linked at ignored `config/local.defines.json`, without copying
credential bytes. Source-only verification found Genius configured and
`VERSE_GOOGLE_MACOS_CLIENT_ID` absent; server/Android IDs alone do not enable
Mac sync. The opaque SHA-256 and booleans are recorded only in ignored
`artifacts/release33-source/private-config-receipt.json`. This verifies input configuration, not successful Genius network operation.
Recheck link target, hash and booleans before configuration/build; abort on drift or enabled Mac
OAuth. Do not print values or copy secrets into tracked files/logs.

The shared implementation can upload song ChordPro and setlist JSON to the
user's Google Drive when sync is configured and authorized. This is user content
sent to a third party, not merely local storage; appDataFolder is a Drive storage
scope, not application-layer encryption. Enabling sync requires reconsidering
Other User Content, linked account information, SDK manifests, Store privacy
answers and public policy for both Apple platforms. Matching app manifests does
not establish SDK-inclusive privacy or legal completeness. No iOS declaration
or public policy has been changed by this reconciliation.

Export option templates are restored for Developer ID and App Store export.
They contain no team IDs, profiles or credentials. App Store export disables
automatic version/build management. Existing ignored owner signing settings
remain untouched. The build script no longer requests provisioning updates or
device registration in build, archive or export; missing local assets should
fail instead of silently creating new signing authority.

## Prepared regression coverage

- Desktop window geometry on Mac, Windows and Linux.
- Mac Space and Command-arrow playback/section navigation, with modal/text
  focus guards.
- Mac editor Flutter Command-S and native channel save; exact changed title/body,
  Control-S negative case and modal-route rejection.
- Native close cancel/discard/clean/dispose lifecycle in the transfer's dedicated
  `macos_exit_test.dart`; no duplicate close test was added.
- Setlist menu click versus immediate mouse reorder and resulting entry order.
- Existing Mac export wording, Save As byte preservation and cancellation tests.
- Hosted Mac workflow includes these tests and unsigned universal compilation.

A macOS-only absolute POSIX `--library-path` parser and explicit native argument
forwarding are added. Missing, relative, duplicate or NUL-containing overrides
fail before opening any database. Windows parsing is unchanged. Prepared parser
regressions cover Unicode/spaces, normalization, equals syntax and fail-closed
cases. Every QA launch must supply the disposable path below.

These tests are prepared but have not been run locally. No Flutter/Dart SDK,
analyzer, test, Xcode, signing, notarization or Store command was run during this
source reconciliation. Source inspection and Git whitespace/blob checks only.

## Bounded validation and release plan, after independent source review

1. Confirm exact frozen source and version CI; coordinate exclusive MacMini SDK
   ownership with the iOS owner. Preserve all old evidence and ignored settings.
2. Run focused desktop, sync routing, export, version/User-Agent and provider
   regressions; analyze and review fresh native screenshots in wide/compact,
   light/dark, large text and RTL configurations. Review hosted CI results.
3. Compile universal Mac app with locked dependencies; run native close, editor
   save via authorized XCUITest, player, drag, Open/Save As, PDF/print cancellation
   and cold-launch persistence against isolated QA data. No normal-user install,
   account/consent or Drive changes. Preserve QA snapshot and content hashes.
4. Archive once source and acceptance pass, recording exact commit/tree/version,
   toolchain, config-enabled feature summary and output hashes without secrets.
   Export Developer ID using existing signing assets, inspect entitlements,
   identities, hardened runtime and both architectures. Submit for notarization,
   staple, verify strict codesign and Gatekeeper; fresh-quarantine launch and hash
   the final ZIP. Never publish unsigned hosted output or overwrite old assets.
5. Publish the qualified platform-specific release only within confirmed release
   authorization, with exact source/feature/runtime limits and checksum. Store
   export/upload needs its own checked metadata/privacy/build association and
   current review-state inspection; preserve the existing 0.2.16 submission.
   No new fees, legal agreements, certificate creation or account changes are
   part of this plan. Intel/macOS 12 runtime remains a limit unless tested.

The source writer stops after pushing this review candidate. No local SDK/build
reservation is held. Local build/sign/notarize/Store work must wait for the
independent review gate and device-owner coordination.

## Exact local command plan (not executed)

Run each command with a supervising process deadline, collecting only sanitized
output. Deadlines below are wall-clock maxima, not permission to run while the
iOS owner holds the SDK slot. Set `PATH` to the existing Flutter SDK after that
slot is explicitly released. Use the frozen worktree and existing ignored input.

| Step | Command | Deadline |
| --- | --- | --- |
| Dependencies | `flutter pub get --enforce-lockfile` | 5 min |
| Localization | `flutter gen-l10n` | 2 min |
| Analyze | `flutter analyze --no-pub` | 5 min |
| Focused regression | `flutter test --no-pub test/application/macos_startup_options_test.dart test/application/windows_startup_options_test.dart test/application/macos_desktop_parity_test.dart test/ui/macos_setlist_drag_test.dart test/ui/macos_exit_test.dart test/sync/macos_platform_drive_auth_test.dart test/sync/platform_drive_auth_test.dart test/ui/macos_account_sync_test.dart test/ui/source_version_widgets_test.dart test/providers/core/transport_test.dart` | 10 min |
| Local QA build | `bash scripts/build-macos.sh release` | 20 min |
| Developer ID archive/export, after QA acceptance | `bash scripts/build-macos.sh developer-id` | 30 min |
| Bundle inspection | `python3 scripts/inspect-macos.py "$MAC_APP"` | 1 min |
| Signature | `codesign --verify --deep --strict --verbose=2 "$MAC_APP"` | 1 min |
| Notarize final signed ZIP | `xcrun notarytool submit "$MAC_ZIP" --keychain-profile "$EXISTING_NOTARY_PROFILE" --wait --timeout 20m` | 22 min |
| Staple and validate | `xcrun stapler staple "$MAC_APP"` then `xcrun stapler validate "$MAC_APP"` | 2 min each |
| Gatekeeper | `spctl --assess --type execute --verbose=2 "$MAC_APP"` | 1 min |

`MAC_APP`, `MAC_ZIP` and the existing notary profile must resolve to that run's
recorded outputs/owner profile; never guess a profile or use stale output. Final
ZIP is rebuilt from the stapled app, then checksummed and freshly extracted.
App Store archive/export, if independently reviewed, uses
`bash scripts/build-macos.sh app-store` (30 min); uploading/submitting is gated on
current Store state, metadata/privacy review and approval of the actual build.
No automatic upload/submission command is included in this preparation.

For **every** candidate, signed-export, quarantined-extraction and cold-relaunch
native launch, set a fresh run-specific QA database **inside the sandbox**:

```sh
MAC_QA_DB="$HOME/Library/Containers/org.freevia.singbook/Data/Documents/macos-qa/release33-RUN_ID/library.db"
"$MAC_APP/Contents/MacOS/Singbook" --library-path "$MAC_QA_DB"
```

Replace RUN_ID with the recorded unique acceptance run ID; never point it at
`Data/Documents/verse_library.db`. Interactive launch deadline is 2 min, each
bounded native acceptance scenario 5 min, total native journey 20 min. Quit only
the owned candidate normally and verify it exited before the next launch. For
XCUITest, set `app.launchArguments = ["--library-path", qaDatabasePath]` on every
launch, with 90-second application readiness and 5-minute per-test limits. Do
not use Finder/open launches that omit the override. Preserve/reopen the same
QA DB only for intentional persistence checks, compare IDs and content hashes,
and leave the normal library untouched. The override must be verified natively
before editing/importing any fixture. Fresh quarantine launch uses the same
explicit executable/argument pair from the fresh extraction, not the old app.
