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
| Linux suite | Complete Flutter unit/widget suite on the local I5 Linux runner | Includes the six UX focused regression files. |
| Windows shards and build | Complete Flutter suite and portable packaging on the local I5 Windows runner | Keep both shard results; retry only a failed shard after inspection, retaining the original failure. These jobs are noninteractive. |
| Desktop OAuth preflight | Secretless PKCE check on the local I5 Windows runner; main only | Validates the public client configuration before packaging. |
| Windows native smoke and journey | Hosted native smoke and deterministic desktop journey | Hosted Windows owns isolated app launch, clipboard, credential and window-state checks. Separate from host widget geometry; never qualifies Android/iOS UI. |
| UX host visuals | 25 dedicated captures with hashed sidecars | Runs on the PR merge tree, matching general CI; review relevant originals. Does not prove native fullscreen or OS dialogs. |
| UX focused / Wikisource | Extra bounded regressions and diagnostics | UX focused runs on manual dispatch; all six files remain in complete CI on PRs. Wikisource explicitly records head-only evidence. |
| macOS compilation | Platform regressions and unsigned universal app | Does not establish GUI acceptance, signing or notarization. |
| Native acceptance | Target platform behavior and representative visual matrix | Use bounded, serialized runs; release the lease and retain evidence on failure. Never replay a consumed grant. |

Keep `linux-build` on hosted `ubuntu-24.04`. Its workflow installs desktop and
packaging dependencies with `sudo apt-get`, then uses ImageMagick, Xvfb, Zenity
and desktop-file utilities. The current `singbook-i5-linux` runner's
`ci-singbook-linux-current` container lacks those packages; its root filesystem
is read-only and sudo cannot elevate. The audit also reports missing
`libgbm-dev` and WebKitGTK 4.0 (only 4.1 is installed), so it cannot build and
exercise the Linux desktop package as configured.

Keep `windows-native-smoke` and `windows-journey` on hosted Windows. They launch
the packaged app and exercise native clipboard, Credential Manager, and window
state in a clean desktop session. The CI configuration identifies the
self-hosted Windows runner as using a persistent interactive profile and does
not declare a separate disposable desktop session for GUI acceptance. Hosted
Windows provides a clean job-scoped session, avoiding interference with that
persistent profile during native checks. These two CI jobs do not require
administrator rights or a trusted signing certificate. The native smoke starts
the app in a normal visible window, temporarily writes to the machine clipboard
and restores its prior contents, and creates then deletes one synthetic
current-user credential. The journey opens the app and changes its window state.
Keep both hosted until the local runner has a disposable interactive session;
the missing capability is desktop/profile isolation, not elevation.

Keep both Store install checks hosted: `test-windows-store-msix-install` and
the `smoke` job in `package-windows-store-release` create a disposable signing
certificate, import it into `LocalMachine\TrustedPeople`, then install and
restart the MSIX. The machine-store import requires administrator rights; a
prior attempt on the persistent I5 runner failed at this import with
`E_ACCESSDENIED`
([run 41288532718](https://github.com/freevia-org/Singbook/actions/runs/41288532718)).
Store package assembly remains on the local Windows runner and hands the exact
artifact to the isolated hosted smoke job.

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

Desktop CI validates the Google OAuth client on the trusted local I5 Windows
runner, on `main` only, with a PKCE token exchange that omits the client secret.
Windows and Linux CI builds, plus the Windows and macOS local build scripts, strip
`SINGBOOK_GOOGLE_DESKTOP_CLIENT_SECRET` from app defines. Desktop OAuth clients
are public clients and cannot keep this value confidential; the app code would
embed it if supplied as a compile-time define. If the preflight reports that
the client requires a secret, desktop CI fails before packaging. Store package
workflows require manifests to explicitly report
`googleDesktopClientSecretConfigured: false`; candidates with a true or missing
flag must be rebuilt from the secretless build path before repackaging.

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
