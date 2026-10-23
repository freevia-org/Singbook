# macOS release candidate — 23 October 2026

The native macOS candidate is **0.2.16 (30)**, bundle ID
`org.freevia.singbook`, targeting macOS 12+. Application source is commit
`8f3d1cda`, based on public main `0a40d7f` (including the latest anonymous
YouTube request fix). Preparation lives on `codex/macos-publishing`; it has
not been merged into main or uploaded to Apple.

## Artifacts

All generated evidence is local and ignored by Git:

`artifacts/macos/20261023T052143Z-8f3d1cda-38951/`

- `Singbook.xcarchive`: signed archive, preserved after verification.
- `export-retry1/Singbook.pkg`: Mac App Store export, approximately 70 MB.
- `Singbook-preview.zip`: development-signed local preview, approximately 33 MB.
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

The Mac App Store package is prepared locally. App Store Connect binary
validation, the macOS platform/listing, SDK-inclusive privacy answers, review
contact, rights/age-rating/territory confirmations and submission remain
owner actions. No upload, submission or privacy-site deployment occurred.

This candidate has **no macOS Google OAuth client or Genius access token**.
The native auth/Picker/Keychain implementation is present, but Google sync
and Genius are unavailable in this binary. Configure and validate real
consent, refresh, account switching, revocation and sign-out before publishing
a build that advertises these integrations. Reuse build 30 until an upload
requires a genuinely new release under the repository's versioning rules.

Native file dialogs, print-dialog cancellation, actual keyboard delivery and
dirty-editor window-close cancellation still need a reliable interactive
acceptance run. Their framework behavior and export byte/cancellation paths
passed automated tests; computer-control input was unreliable during native
inspection. Intel runtime and clean-machine installation were not tested.
The generated Xcode RunnerTests target was not executed separately.

A Developer ID Application identity is not installed, so a notarized
direct-download distribution was not created. The Mac App Store `.pkg` is
not a direct-download installer. The development preview ZIP is for local
review. See [publishing steps](macos-publishing.md) for both routes.

All delegated work is integrated and reviewed. No physical device, simulator,
shared build directory or ongoing Flutter/Xcode process is reserved. The
isolated worktree, verified archive, signed package and evidence remain for
handoff.
