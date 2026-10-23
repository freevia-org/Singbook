# macOS release candidate — 23 October 2026

The native macOS candidate is **0.2.16 (30)**, bundle ID
`org.freevia.singbook`, targeting macOS 12+. Application source is commit
`8f3d1cda`, based on public main `0a40d7f` (including the latest anonymous
YouTube request fix). Preparation lives on `codex/macos-publishing`; it has
not been merged into main. Build 30 was uploaded to Apple, processed and
selected for the macOS draft on the existing Singbook app record. No macOS
review submission or release has occurred; iOS 0.2.10 remains waiting for review.

## Artifacts

All generated evidence is local and ignored by Git:

`artifacts/macos/20261023T052143Z-8f3d1cda-38951/`

- `Singbook.xcarchive`: signed archive, preserved after verification.
- `export-retry1/Singbook.pkg`: Mac App Store export, approximately 70 MB.
- `Singbook-preview.zip`: development-signed local preview, approximately 33 MB.
- `developer-id-export/Singbook.app`: Developer ID-signed direct-download
  candidate; notarization subsequently accepted.
- `Singbook-developer-id.xcarchive`: cloned archive submitted for notarization,
  preserving the verified original archive.
- `package-report.json`, `archive-report.json`, `bundle-report.json`,
  `SHA256SUMS`, source revision/status/diff and build/archive/export logs.

The package SHA-256 is
`10f5359472c919c6df3e19c39b2a9fa914e26fdf2526516031af2f53ab843a41`.
Package inspection verified Apple Distribution application signing, a
`3rd Party Mac Developer Installer` certificate in the installer chain, and
an OSX profile with no development-device allowlist. The exported app passed
`codesign --verify --deep --strict`. Both `arm64` and `x86_64` are present.
Release hardened runtime is enabled, the release JIT entitlement is absent,
and sandbox/network/user-selected-file/printing entitlements are present.
Eighteen privacy manifests are bundled; the app manifest matches source.

The initial export failed because its temporary volume ran out of space.
Only this worktree's intermediate cache and its separately identified scratch
DerivedData were removed. The existing archive was then exported successfully
without rebuilding or modifying it. Original checkout iOS/Android artifacts,
credentials and unfinished contributor changes were preserved.

## Validation

Toolchain: Flutter 3.44.8, Dart 3.12.2, Xcode 27.1; Apple Silicon host.
Locked dependencies were retained, with no package upgrades.

- Full Dart suite before the final bounded UI additions: **1,770 passed,
  13 skipped**. Follow-up checks covered every subsequent source change.
- Final combined macOS desktop/auth/settings/drag, Windows input/exit,
  localization/version and transport/User-Agent checks: **62 passed**.
- Account settings tests including the new macOS controls and existing
  Android behavior: **67 passed**. Mouse row drag test: **1 passed**.
- Latest upstream YouTube consent/request regression tests: **13 passed**.
- Final `flutter analyze --no-pub`: no issues. Localization generation
  produced no source drift; displayed version and User-Agent checks passed.
- Native macOS integration: **3 passed**, including a real HTTPS catalog
  fetch through the native transport and sandbox, isolated Keychain
  create/read/update/delete plus invalid OAuth callback rejection, SQLite
  close/reopen with matching song ID/body, and native PDF rasterization.
  Tests used unique disposable databases and `--no-uninstall`.
- Fresh native renderer captures reviewed: 1280×800 English light,
  800×600 Ukrainian dark at 150% text, and 390×720 Arabic RTL dark at 160%
  text, each showing library and reader. A native window reader capture was
  also inspected. Compact title/label truncation remains visible at extreme
  text scale; no Flutter layout exception occurred.

Logs and screenshot originals are under `artifacts/macos-acceptance/`.
`store-en-US-library.jpg` and `store-en-US-reader.jpg` are 1280×800 without
alpha channels. Listing text limits and screenshot dimensions were checked.
See `docs/mac-app-store/` for the exact offline candidate profile and review
notes. Those demonstration songs are not preloaded in the release app.

## Publishing handoff and limits

The macOS version 0.2.16 (30) was submitted for review on 23 October 2026
at the owner's request. App Store Connect confirms **Waiting for Review**.
Automatic release after approval is saved. Submission ID:
`1b1a0272-ee5c-4a4c-9864-8f18de8abecb`. Mac-specific English text, two
screenshots, original review fixtures, sandbox notes and the existing review
contact were retained. No privacy-site deployment occurred.

This candidate has **no macOS Google OAuth client or Genius access token**.
The native auth/Picker/Keychain implementation is present, but Google sync
and Genius are unavailable in this binary. Configure and validate real
consent, refresh, account switching, revocation and sign-out before publishing
a build that advertises these integrations. Build 30 has now been uploaded. Further binary changes require
`0.2.17+31` under the repository's versioning rules; do not overwrite build 30.

Native file dialogs, print-dialog cancellation, actual keyboard delivery and
dirty-editor window-close cancellation still need a reliable interactive
acceptance run. Their framework behavior and export byte/cancellation paths
passed automated tests; computer-control input was unreliable during native
inspection. Intel runtime and clean-machine installation were not tested.
The generated Xcode RunnerTests target was not executed separately.

The owner explicitly approved creation/import of a Developer ID Application
certificate. Its matching private key was verified and imported into Keychain.
The direct-download export passed deep/strict signature verification and has
hardened runtime and a secure timestamp. Xcode uploaded the cloned archive
successfully for notarization; Apple accepted it. The exported app passed
deep/strict signature verification, stapled-ticket validation and Gatekeeper
assessment (`Notarized Developer ID`). The final archive is
`Singbook-0.2.16-macos-universal.zip`; its SHA-256 is
`f24273b25e50faf46a80ffb20b01cd8140f583b3dc64d734f72ef39bff468b33`. Public GitHub publication remains pending
clean-machine and interactive acceptance; no public asset URL exists yet. The Mac App
Store `.pkg` is not a direct-download installer. The development preview ZIP
is for local review. See [publishing steps](macos-publishing.md) for both routes.

All delegated work is integrated and reviewed. No physical device, simulator,
shared build directory or ongoing Flutter/Xcode process is reserved. The
isolated worktree, verified archive, signed package and evidence remain for
handoff.
