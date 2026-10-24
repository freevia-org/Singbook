# Integration, validation and release

Use one coordinator, one release candidate and one evidence index. Keep historical
receipts immutable; the current index should link to them instead of copying logs,
images and old discussions into every handover. An owner report is a pointer to
evidence, not a substitute for reviewing the diff and results.

## Working sequence

1. Start from current public `origin/main` in a clean worktree. Inspect shared
   changes first. Assign independent tasks with one writer per file; reserve a
   device or SDK only for the phase that actually needs it.
2. Reproduce the reported behavior with a focused regression. For asynchronous
   bugs, vary completion order under the same operation as well as cancellation
   and stale operations. A final static screenshot cannot establish streaming
   behavior. Review the implementation diff before expanding validation.
3. Run the focused checks once, then the combined checks on the final candidate.
   Change source or runtime configuration only between phases. Record commit,
   tree, lockfile, configuration fingerprint and tool versions with each result.
   Never include credential values in evidence.
4. Batch accepted changes before reserving a new patch/build number. Update the
   four version surfaces together and run the existing drift checks:
   `flutter test --no-pub test/ui/l10n_test.dart test/providers/core/transport_test.dart`.
   A retry or track promotion keeps that release number.
5. Build each distributable once from frozen inputs. Inspect the actual package,
   signer, version, identity, resources and provenance. Run native acceptance on
   an isolated library. Promote the verified package by hash; packaging and
   submission do not require another Flutter compilation.
6. Submit once and record the returned submission/build identity. Separate
   submitted, in review, approved and publicly available states. Monitor only
   pending submissions; notify public availability once, then retire that poll.

## Validation lanes

| Lane | Purpose | Reuse and limits |
| --- | --- | --- |
| CI analysis | Generated localization drift and Dart analysis | Required before Windows fanout; locked dependencies. |
| Linux suite | Complete Flutter unit/widget suite | Includes the six UX focused regression files. |
| Windows shards | Complete suite split across two jobs | Keep both results; retry only a failed shard after inspection, retaining the original failure. |
| Windows build and journey | Portable packaging, native smoke and deterministic desktop journey | Separate from host widget geometry; never qualifies Android/iOS UI. |
| UX host visuals | 25 dedicated captures with hashed sidecars | Runs on the PR merge tree, matching general CI; review relevant originals. Does not prove native fullscreen or OS dialogs. |
| UX focused / Wikisource | Extra bounded regressions and diagnostics | UX focused runs on manual dispatch; all six files remain in complete CI on PRs. Wikisource explicitly records head-only evidence. |
| macOS compilation | Platform regressions and unsigned universal app | Does not establish GUI acceptance, signing or notarization. |
| Native acceptance | Target platform behavior and representative visual matrix | Use bounded, serialized runs; release the lease and retain evidence on failure. Never replay a consumed grant. |

Resolve dependencies once per job with the committed lockfile. Use `--no-pub`
for subsequent commands in that prepared job. Separate jobs need their own
resolution; do not share mutable build directories to save startup time.

## Artifact reuse

The `windows-release-bundle` artifact contains only the portable ZIP and matching
manifest; native logs stay in `windows-validation-evidence`. Store packaging
consumes the exact pinned CI run/artifact/digest, validates source and portable
hashes, and packages the existing payload. Its name and manifest contract are
stable. Candidate bundles are retained for 90 days (subject to repository policy).
This is a staging window, not permanent archival storage: preserve qualified
release assets and receipts durably before expiry. Longer retention does not
restore expired historical pins.

Use `scripts/build-android.ps1` for Android. Bundle/symbol destination collisions
fail before Flutter starts, and are checked again before copying. Reuse verified
output; an explicit `-Force` is only for intentional replacement of unverified
local output. Preserve verified packages. Run `scripts/verify-release.ps1` on the
actual signed APK/AAB with the expected version arguments; independently compare
the trusted signer and package identity because the current verifier's signer
rule only excludes debug keys.

`scripts/build-ios.sh` performs one locked dependency resolution and disables
implicit resolution during builds. The macOS script already does so. Apple
signing/export/notarization must qualify the final exported payload; a preview
build or passing helper model does not establish that qualification.

## Review measurements

On release34 PR CI run `40104660831`, analysis took 51 seconds, Linux tests
5m38s, Windows shards 6m43s and 6m59s, Windows build 5m17s, and journey 4m49s.
UX run `40104660933` added 1m26s for the duplicate focused job and 56 seconds for
unique host visuals. Main branch protection returned absent and repository
rulesets were empty at review. The focused job is now manual-only; its tests
remain in both full suites. Job names and the unique visual lane are retained.
These are baseline observations, not a measured speedup for this patch.

## Remaining consolidation work

- Retire release28 dispatch workflows in favor of the consolidated Store lane
  after confirming no required checks or owners depend on them. Do not repin an
  expired historical release as a workaround.
- Refactor macOS archive modes to inspect the archive's app directly and avoid
  the separate preview build, with resource/signature parity checks before use.
- Strengthen Android verification with expected signer/package checks and
  fail-closed missing version metadata; qualify this against real packages.
- Preserve machine-readable Windows test outcomes to diagnose the existing
  shard timeouts. Do not add blanket retries or claim their cause is established.

## Coordinator handover

Send a short current-state summary, active ownership, pending actions and hashes
or paths to receipts. Keep large evidence in ignored files or durable artifacts.
Use a transfer archive only when the receiver cannot access those files; verify
its manifest once, preserve the original snapshot, then atomically install the
ledger with a concurrency guard and last-good backup. Transfer exactly one
monitor and one ledger writer. No handover requires rebuilding or resubmitting
an unchanged release.
