# Source catalog and daily maintenance

`config/source-catalog.json` is the published, complete source list. The Flutter
app bundles that file, restores a compatible cached snapshot, and refreshes from
the same file on public GitHub `main`. `SINGBOOK_SOURCE_CATALOG_URL` can override
the HTTPS publisher URL at build time. Settings → Sources → Refresh source list
performs the same refresh manually. A new app build containing this implementation
is required before an existing installation can consume catalog updates.

The catalog is declarative data; it never downloads Dart, JavaScript, credentials,
headers or executable repair code. A failed download, bad extraction rule,
unsupported schema, rollback, or failed cache write preserves the previous live
and durable snapshot. Bundle and cache loading do not depend on a network call.
No provider update changes saved songs, ChordPro provenance or user preferences.
Catalog storage is separate from the user's synced application settings.

## Version and lifecycle contract

The envelope has `schemaVersion: 1`, `extractionSchemaVersion: 1`, a positive
monotonically increasing `revision`, UTC `publishedAt`, and a `sources` array
(at most 100 entries and 512 KiB for the complete document). Each entry has:

| Field | Meaning |
| --- | --- |
| `id` | Stable provider identifier; keep it across endpoint/layout changes. |
| `revision` | Positive per-source revision; increase it whenever that entry changes. |
| `name`, `website`, `description` | Display/provenance information. Website must be public HTTPS. |
| `adapter` | `builtin`, `json`, or `html`. Unknown builtins require an app release. |
| `status` | `active`, `disabled` (temporary), or `retired` (withdrawn). |
| `enabledByDefault`, `accessMode` | Initial preference and documented access method. Existing user choices win. Token-backed builtins remain unavailable without their configured credentials. |
| `capabilities` | Supported output families, such as `catalog`, `lyrics`, `chords`, `metadata`, `lineTiming`, `wordTiming`, or `fileImport`. |
| `hosts` | Exact public HTTPS hosts for declarative adapters; no wildcards, IPs or local hosts. Builtins retain their compiled host policies. |
| `attribution` | Optional required provider credit carried into each extracted result. |
| `extraction` | Rules for a JSON/HTML adapter; absent for builtins. |
| `probes` | Known-song checks with explicit identity and expected fields. |
| `changeReason` | Evidence-backed reason for the latest source change. |

The list is a complete snapshot. Disabled/retired and omitted entries disappear
from active lookup, even when the user previously enabled them. Prefer explicit
retirement over omission so that the reason and stable ID remain auditable.
An entry can later reactivate at a higher revision; the user's stored preference
still applies. A rollback is a **new**, higher catalog/source revision containing
the restored rules; never decrease revision numbers or change published content
at the same revision.

Incompatible envelope or extraction grammar versions are rejected as a whole.
Keep this v1 endpoint compatible with shipped v1 clients. A new grammar/operator
or native integration needs code, tests and an app release plus a separately
versioned publication path before being enabled for those clients. Updating CSS
selectors, JSON paths, endpoints or capabilities within the existing grammar
does not require an app update.

## Declarative extraction grammar v1

`extraction.search` has `url`, `response` (`json`/`html`), `fields`, and either
`itemsPath` (JSON dot path to an array) or `itemSelector` (HTML CSS selector).
Search fields are `id`, `title`, `artist`, and optional `url`, `album`,
`durationSeconds`. `extraction.resolve` has `url`, `response`, optional JSON
`rootPath`, and `fields` for `title`, `artist`, `body`, optional `album`,
`durationSeconds`, `format`, and `metadata`. Title/artist are verified against
the selected result. Metadata-only adapters may omit body but must supply a
nonempty metadata mapping and return useful sanitized metadata.

A JSON field is a bounded dot path (`song.artist.name`, `items.0.title`).
An HTML field is `{ "selector": "h1", "attribute": "content" }`; omit
`attribute` for text. An ordered list of field specifications provides bounded
fallbacks. Lyric extraction preserves HTML line/paragraph breaks. Invalid
selectors, unknown keys and unsupported operators fail catalog validation.
Metadata keys use the existing provider sanitizer (album, key, time signature,
tempo, duration, year, language, tuning, capo, genre, credits, and safe links).
Metadata is never accepted as injected Singbook extension directives.

URL placeholders are `{query}`, `{id}`, `{title}`, `{artist}`; each value is URL
encoded and may not alter the host or scheme. A resolve URL consisting solely of
`{url}` may follow the selected result's URL after the same host validation.
HTTP requests still use the existing pacing, cancellation, response limits,
same-site redirects and block detection. Consent pages, CAPTCHA and access
denials remain failures.

`bodyFormat` accepts `plain`, `chordpro`, `lrc`, `ttml`, or `auto` (use the mapped
`fields.format`, accepting only `plain`, `lrc` and `ttml`). Raw LRC/TTML is retained
with its original timing. Parsing a timed document does not establish recording
identity or make its cues safe to activate; existing match/combination rules
continue to decide that. Remote extension directives are stripped. Provider
attribution and source URLs are retained; remote configuration does not establish
new redistribution rights.

## Run the validator

Use the Flutter-bundled Dart SDK, after `flutter pub get`:

```powershell
dart run tool/source_maintenance.dart --offline --report artifacts/sources-offline.json
dart run tool/source_maintenance.dart --report artifacts/sources-live.json
dart run tool/source_maintenance.dart --source lrclib --report artifacts/lrclib-live.json
```

Options also include `--catalog path` to validate a candidate catalog. Offline
mode checks parsing, adapter construction and probe coverage; its results are
explicitly `offline_unverified`, never proof of live health. Live mode checks
every registered source, including those disabled by default. Import-only,
disabled and retired sources have explicit skipped states. A source missing from
the catalog or lacking a probe is a coverage gap, not a successful check.

A probe contains a stable `id`, either `candidate` (SongCandidate JSON) or `query`
with `expectedTitle`/`expectedArtist`, optional `expectedAlbum` and
`expectedDurationSeconds`, `requiredFields` (`body`, `chords`, `timing`,
`lineTiming`, `wordTiming`, `metadata`) and optional `requiredMetadataFields` (bounded paths in the normalized
metadata). Use explicit recordings, composition identities or Commons file IDs
as appropriate. Multiple ambiguous search matches do not become the first hit.
Choose at least two independent canaries for new or repaired content extraction.
Cover each claimed content capability with an appropriate canary; a field that
varies by song must not become required for every song. Optional variants not
required by a canary remain unverified, even when that canary is healthy. Reports
show the timing granularities actually observed. Embedded selection IDs, such as
SyncLRC's encoded records, are reported as fingerprints instead of raw IDs.
Line/word cue checks require nonempty raw documents and valid parsed cues. Line
coverage requires an explicit line cue; word coverage requires positioned word
cues with valid grapheme bounds. A combined word track may contain both. A raw
document alone proves retention, not working cues.
Reports list `coverage.verifiedCapabilities` and `coverage.unverifiedCapabilities`;
passing canaries with advertised but untested capabilities are `partial_coverage`,
which also returns exit 1. Extend coverage when a representative real canary is
available; incomplete coverage alone does not justify retiring a source.

Reports include timestamp, source/probe IDs, outcome, missing field names,
lengths/counts and metadata field names. They contain no full lyrics, raw source
documents or credentials. The normalized SourceResult JSON is round-tripped to
check model compatibility and raw timing retention. Live issues return exit 1;
invalid configuration/arguments or file errors return exit 2. Exit 0 in offline
mode means only that static validation succeeded.

Genius uses `GENIUS_ACCESS_TOKEN` from the environment or ignored
`config/maintenance.defines.json`; missing credentials produce `not_configured`.
Create that file from `config/maintenance.defines.example.json` and supply the
maintenance client access token. The checker never falls back to the app's
`config/local.defines.json`: app and maintenance credentials can be rotated
independently. Existing local setups must provision the maintenance file once.
Local credentials are not uploaded to the hosted environment. Cloud maintenance
needs its own `GENIUS_ACCESS_TOKEN` secret binding, supplied through the managed
environment's secure configuration rather than a repository or chat message.
Windows probes use the test-only curl transport to handle HTTP Early Hints;
mobile lookup continues to use Cronet/NSURLSession. Every probe has a bounded
deadline and cancellation, and transport retries/pacing still apply.

`integration_test/source_catalog_device_test.dart` exercises the native HTTP
client and asset/cache lifecycle. Run Flutter integration tests only on an
isolated test installation with no user library. This Flutter SDK defaults to
uninstalling its application package at teardown; explicitly pass
`--no-uninstall` when package retention is required. A later `adb install -r` cannot preserve
data from a package already removed by the runner. Normal app upgrades use the
approved build script and replacement installation; never use integration-test
deployment as a data-preserving upgrade path.

## Daily repair and discovery procedure

### Local YouTube Music consent

The desktop checker has its own optional anonymous browser session. It does not
use the Android/iOS WebView session or your normal Chrome/Edge profile. Start a
review on this machine with an installed Chrome or Edge browser:

```powershell
dart run tool/source_maintenance.dart --source youtubemusic --youtube-consent --report artifacts/source-maintenance/youtube-local.json
```

If Google presents a cookie choice in the dedicated browser window, make it
there; do not sign in. Google may return straight to the Music homepage without
requesting a choice. After the return, the checker reads only applicable
`SOCS`/`CONSENT` cookies, closes the window, and runs the real provider probe.
An anonymous return is not recorded as a person making a consent decision.
Cookie presence alone is not a passing extraction result. Cancelled, timed-out
or incomplete sessions cannot be restored. Running `--youtube-consent` again
starts a fresh review.

The isolated browser profile lives outside the checkout: on Windows under
`%LOCALAPPDATA%/Freevia/SingbookMaintenance/YouTubeMusic`, on macOS under
`~/Library/Application Support/Freevia/SingbookMaintenance/YouTubeMusic`, and on
Linux under `$XDG_DATA_HOME/freevia/singbook-maintenance/youtube-music` (or
`~/.local/share` when unset). Chrome manages its native cookie storage. The
checker writes a session-presence marker and whether the chooser was presented,
not a portable cookie jar.
Treat that dedicated profile as private browser data; never copy it to the
repository, report branch, cloud worker or another computer.

Later local runs restore this profile without opening a visible window or
making a browser origin request. Status and clearing are explicit operations:

```powershell
dart run tool/source_maintenance.dart --youtube-session-status
dart run tool/source_maintenance.dart --source youtubemusic --report artifacts/source-maintenance/youtube-local-recheck.json
dart run tool/source_maintenance.dart --youtube-clear-consent
```

Clear removes only the two consent-cookie names applicable to the Music and
consent hosts, and disables restoration before reporting success. Other sources,
the mobile app, Drive sign-in and the normal desktop browser are independent.
Reports contain presence/error codes and extraction shape metadata, never cookie
values or lyric bodies. The Windows curl transport puts sensitive request
headers in a temporary local file instead of process arguments, then removes
the temporary directory after each request. An interrupted process can leave
that temporary file behind; it is private session data too. If Chrome/Edge cannot
be found, `--youtube-browser` can specify the installed browser executable.
Concurrent access to the profile is refused. Browser use keeps TLS verification
and configured proxy access intact;
proxy URLs containing credentials are refused rather than exposed in arguments.

This is an experimental unofficial web session. Google can expire the decision,
deny access or change its page; renew the review when requested. A platform
CONNECT denial happens before this flow and cannot be repaired with cookies.
The cloud job does not acquire or upload this local session. This command does
not change the local daily timer or start an unattended consent/sign-in flow.

### Hosted daily job

The owner's daily task runs at 09:00 Europe/Kyiv in a private Codex Cloud
environment using the ChatGPT/Codex subscription. It does not require the owner's
computer, local files, or desktop app. The owner also enabled a complementary
local daily heartbeat for sources reachable from this machine. Keep both enabled:
local success does not establish cloud reachability, or vice versa. Local reports
use `reports/source-maintenance/local/latest.json` plus UTC-dated history on
`codex/datasource-health`; `reports/source-maintenance/latest.json` remains
cloud-owned. Preserve the other runtime's reports through non-forced updates.
Environment publication, GitHub access, and the hosted schedule are account
configuration, separate from this repository's
catalog. See [cloud environments](https://learn.chatgpt.com/docs/environments/cloud-environments)
and [scheduled tasks](https://learn.chatgpt.com/docs/automations).

The [scheduled smoke report](https://github.com/freevia-org/Singbook/blob/e67c5305b5d2134be8b27e0d7d0e8faf60677589/reports/source-maintenance/latest.json)
records actual managed-cloud execution of the validator. It is explicitly
`offline_unverified`: it proves the timer/runtime path, not source health. The
first normal daily run establishes the durable live baseline.

The prepared Linux environment includes the Flutter version pinned by CI and its
locked dependencies. No Android SDK, device, emulator, app build, signing material,
or OpenAI API key is needed. Activate the writable cache locations in each shell:

```bash
export PATH=/workspace/toolchains/flutter/bin:$PATH
export PUB_CACHE=/workspace/.pub-cache
export XDG_CONFIG_HOME=/workspace/.config
export ANALYZER_STATE_LOCATION_OVERRIDE=/workspace/.dart-state
export CI=true
cd /workspace/Singbook
flutter pub get --enforce-lockfile
```

Use the Singbook-only GitHub connection for reports and review PRs. Keep secrets
in the cloud environment's secure configuration; never copy or create
`config/local.defines.json` or `config/maintenance.defines.json` there.
Missing `GENIUS_ACCESS_TOKEN` remains
`not_configured`. A cloud proxy CONNECT denial is an environment access problem,
even when the saved policy permits the host, and is not evidence of an upstream
schema change. Do not bypass the proxy or disable TLS verification.

1. Inspect Git state, current public history, this guide, catalog and previous
   durable reports. Use the current runtime's isolated checkout, fetch public
   `main`, and preserve unfinished changes. Cloud execution must not depend on a
   Windows checkout, local integration chat, or a connected computer. Local runs
   use only their dedicated maintenance credentials/profile and coordinate source
   handoffs with the integration owner.
2. Run all live probes against the current catalog, writing a dated report under
   ignored `artifacts/source-maintenance/`. Persist the sanitized report and its
   latest summary on the dedicated `codex/datasource-health` GitHub branch;
   compare that branch's prior report, rather than assuming an old cloud VM or
   ignored file survives. Keep report history separate from source-change PRs
   and do not open report-only PRs. Local runs compare both local and cloud
   evidence, preserving runtime/source/probe/timestamp provenance. A missing
   credential is a coverage limitation, never a schema repair or a healthy source.
3. Diagnose changed extraction and missing fields against the actual source and
   primary documentation. Repair compatible rules, or a compiled adapter when
   necessary; add synthetic regression fixtures from the smallest required
   structural evidence. Preserve rights, attribution, source identity and raw
   timing. Re-run the affected real canaries and relevant tests before promoting.
4. Do not retire a source because of a single timeout, rate limit, access block,
   cache miss or absent song. Retry later according to server policy. Disable an
   unusable extraction only with repeated independent evidence or an explicit
   operator withdrawal; keep its tombstone/reason and preferences. To check
   recovery of a temporarily disabled source, probe a temporary active copy of
   its configuration without publishing that copy; reactivate only after its
   real canaries pass. Retired sources require fresh availability/access evidence.
5. Search the web for additional APIs, open song catalogs and regional/language
   coverage, checking publisher documentation and actual HTTPS responses. Keep
   discovery decisions in `config/source-discovery.json`; include dates, source
   URLs, duplicates/overlap and reasons for rejection or deferral. Do not assume
   that an open-source client grants access to its upstream data.
6. Add a source only after identity, fields, attribution, access requirements and
   at least two real canaries pass. Compatible sources use declarative adapters;
   new grammar/native code stays pending an app release. Promote healthy
   candidates into the catalog with stable IDs. If no candidate qualifies,
   retain the evidence and continue on the next day without adding a dummy.
7. Increase changed source revisions and the global revision, update UTC
   publication time, and run static validation, provider/controller regressions
   and analysis. Re-probe changed/new sources using the final candidate config.
   Validate the whole catalog and keep unchanged external outages explicit.
8. Commit only owned, validated source changes on a task branch based on current
   public history and open or update a GitHub review PR. Include exact base/head,
   file list, dated redacted report and test/canary evidence. Keep merges, public
   `main` publication, and app releases with the integration/release owner;
   a prepared PR is not a published catalog update. After an accepted merge,
   verify the served catalog matches the integrated revision before calling an
   update published.
   Never push old canonical history, publish app-store builds, overwrite secrets,
   clear user data or force-push as part of maintenance.

The local heartbeat stays quiet only when there are no roadblocks or meaningful
changes. Report every local roadblock, including recurring ones: affected source
or step, safe reason, what was tried, whether it resolved, and any user action
needed. Include incomplete capability validation, access denials, expired consent,
credential failures, outages and failed checks/report publication. Record
validated repairs/additions and distinguish prepared changes from publication.
Record unresolved issues honestly; automation is a
maintenance loop, not a promise that every inaccessible upstream can be repaired.
