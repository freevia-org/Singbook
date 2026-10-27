# Source catalog and daily maintenance

`config/source-catalog.json` remains the complete channel-1 source list used by
released clients through build 38. Keep this file and its URL compatible with
those clients. `config/source-catalog-v2.json` remains the complete channel-2
bundle and refresh URL for the compatible build-39 runtime.
`config/source-catalog-v3.json` is the complete channel-3 bundle and refresh URL
for the AMLL runtime. `config/source-catalog-v4.json` remains the complete
channel-4 VocaDB bundle and refresh URL. New candidate code uses
`config/source-catalog-v5.json`, adding TouhouDB and UtaiteDB, as its complete
channel-5 bundle and refresh URL on public GitHub `main`. The new code/catalog
still require integration and a compatible app release.
These are distribution channels; all five files use envelope/extraction schema
version 1.
`SINGBOOK_SOURCE_CATALOG_URL` can override
the HTTPS publisher URL at build time. Settings → Sources → Refresh source list
performs the same refresh manually. A new app build containing this implementation
is required before an existing installation can consume catalog updates.

The catalog is declarative data; it never downloads Dart, JavaScript, credentials,
headers or executable repair code. A failed download, bad extraction rule,
unsupported schema, rollback, or failed cache write preserves the previous live
and durable snapshot. Bundle and cache loading do not depend on a network call.
No provider update changes saved songs, ChordPro provenance or user preferences.
Catalog storage is separate from the user's synced application settings.
Channel 5 reads/writes `sourceCatalog:v5` and never overwrites
`sourceCatalog:v4`, `sourceCatalog:v3`, `sourceCatalog:v2`, `sourceCatalog`, or provider preferences. It starts from
its own bundled snapshot when the new cache is absent; independently higher
older-channel revisions cannot lock out channel-5 updates. Channels 2, 3 and 4 retain
their existing caches and URLs. Unknown native providers cause a refresh to fail
before any live/cache mutation. Never add an unknown native ID to an older
channel, even disabled. AMLL is absent from channels 1/2; VocaDB is absent from
channels 1/2/3; TouhouDB and UtaiteDB are absent from channels 1/2/3/4.

Channel 2 enables lrc.red, Roswell Music Jam and kara.moe for compatible app
builds. Channel 3 inherits all 22 channel-2 entries without altering them and
adds AMLL enabled by default for the new compiled runtime. Existing saved
opt-outs win. Channel-1 and channel-2 apps keep their source lists, URLs and
cache streams. Channel 4 preserves all 23 channel-3 entries and adds VocaDB
active and enabled by default for its new compiled runtime. Channel 5 preserves
all 24 channel-4 entries and adds TouhouDB and UtaiteDB active/default-on for its
new compiled runtime. Their fixed-host parsers retain every lyric variant,
credit, alias, role, album and original-version relationship. They do not borrow
a parent's lyrics for a cover/remaster with no original lyric of its own.
Contextual title
lookup, complete lyric-variant/artist-role facts and mutable detail caching use
the ordinary provider service. Existing saved opt-outs still win. Frozen
release-39 artifacts are not rebuilt by this change. Native
qualification covers real search/import, cached readers, artwork decoding and
exact source-payload retention across SQLite reopening and ChordPro round trips;
it does not establish independent lyric transcription or musical accuracy.
The lrc.red native adapter uses the publisher's identifying User-Agent,
exact ISRC search/detail identity, same-host TTML/artwork references and visible
attribution. Its explicit timing profile handles the publisher's bare-second
and short media clocks without changing generic TTML semantics. Album artwork
remains linked source metadata; no blanket redistribution license is claimed.

Roswell Music Jam is active on channel 2. It discovers the latest
publisher-linked all-ChordPro ZIP from the public songbooks page, checks a
bounded single-disk archive in memory, and exposes individual chart selections.
Successful downloads are cached for 24 hours per provider instance, so searches
and resolving multiple selections reuse one archive. Failed refreshes are
reported without replacing the prior cache. Filenames identify arrangements;
artist tags are not treated as recording identities. Imported charts retain
source attribution, archive revision, original ChordPro and unknown rights.
No publisher corpus is automatically imported into a user's library.

The kara.moe adapter uses the documented public search/detail API and
retains its parsed lyric-line timeline and the full original detail JSON,
including subtitle tags. These are karaoke-video arrangements: KIDs are source
identities, not recording IDs; video year/duration remain source-specific facts.
Timing carries `recordingEvidence: sourceDemonstrationOnly`, so it cannot become
verified playback timing for an unrelated studio recording or cover. Parsed
line timing does not imply that subtitle syllables are verified word timing.
Database licensing, synchronization attribution and lyric rights remain
separate. The native adapter is active only in channel 2, which requires a
compatible app release; it never downloads a video or signs in.

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

Options also include `--catalog path` to validate a candidate catalog. Both
offline and live CLI defaults follow the app's current bundled channel (now 5).
An explicit older `--catalog` still parses/applies that snapshot, but the full
current registry reports newer compiled providers intentionally absent from it
as coverage gaps; this is not evidence that an older app's source list is broken.
To qualify a pending
native source before release, use an ignored temporary active copy with
`--catalog` and `--source`; do not publish that copy or change the disabled
rollout entry merely to make a probe run. Released channel-1 clients and their
published catalog remain unchanged.
Offline mode checks parsing, adapter construction and probe coverage; its results are
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
For search checks with multiple same-name arrangements or recordings, include
both the existing `query` and `candidate` fields. The checker requires that
exact provider/stable ID once in the search response, checks its identity, and
then resolves that declared selection. It never chooses the first same-name
result. Historical-text search may omit the author, but resolution must still
verify the declared author and per-work rights. Candidate-only probes verify
direct retrieval and do not establish catalog-search coverage.
Local file-ingestion regression tests exercise the app's decoder with synthetic
documents. They do not verify a publisher's download workflow or establish live
`fileImport` coverage. Keep that capability unverified until an actual permitted
download canary has been imported and its identity, chords, metadata and credits
checked. Do not replace login or bot-challenge pages with guessed download URLs.
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

### Scheduled catalog selection and request budget

For production daily runs, use an isolated checkout of current public `main`
and the CLI's default catalog. Confirm that this default matches
`SourceCatalogClient.bundledAsset` in `lib/providers/source_catalog_client.dart`.
Derive the roster from that runtime's complete compiled registry and matching
bundle. Do not pin a scheduled run to an older channel after a compatible runtime
has advanced, or hardcode the number of providers. Keep every older served
catalog compatible with its released app.

Before live requests, run one offline structural check. A missing registered ID,
unknown native ID or catalog/runtime mismatch is an explicit coverage problem;
resolve the checkout/configuration mismatch without downgrading the roster.
Record the source commit, runtime, catalog path/channel/revision and measurement
time in each sanitized report. Pending feature branches use separate candidate
qualification reports and never replace production `latest.json` for either
runtime. Integrating a new channel does not prove that a released app consumes it.

Run the complete live suite once per scheduled invocation. Each source can have
multiple search/detail canaries, redirects and bounded transport retries, so one
daily job does not mean one HTTP request per host. Retain those measured counts
and timestamps, including any separate publisher file-import phase. A selected
source recheck needs changed response evidence, an actual code/config repair or
a specific new capability; state that reason and reuse fresh evidence for
unchanged sources. Local and cloud jobs each retain their own daily run and
provenance. A rate-limit response alone does not prove a daily scheduling problem
or establish whether the limit is per client, shared IP or upstream global load.

The saved local and cloud schedule prompts are account configuration. When
changing their catalog selection, preserve both enabled jobs, cadence, target
worker/environment, credentials and notification preferences. Verify each saved
prompt separately; editing a repository guide or one runtime's prompt does not
prove that the other runtime adopted the change.

### Publisher file-import checks

The opt-in host check downloads two exact Ozbcoz guitar arrangements from links
observed in its public ChordPro index, then runs the production file decoder,
controller import, disposable SQLite save/reopen and ChordPro export. It verifies
title/artist, key, chord order, original comments and exact stored/exported data.
It uses no browser profile, cookies, user library or native file picker. A
challenge, missing file or wrong identity fails instead of selecting a substitute.

```powershell
$env:SINGBOOK_LIVE_IMPORT_CHECK = '1'
flutter test --no-pub tool/source_import_maintenance_test.dart
Remove-Item Env:SINGBOOK_LIVE_IMPORT_CHECK
```

On Linux/macOS use
`SINGBOOK_LIVE_IMPORT_CHECK=1 flutter test --no-pub tool/source_import_maintenance_test.dart`.
Normal offline test runs skip these network requests. The redacted result is
`artifacts/source-maintenance/imports-live.json`; retain a dated copy with the
daily report. It records its own runtime/timestamp and HTTP counts. Report this
supplemental host import evidence alongside the regular CLI result: the CLI's
`import_only` state remains an accurate description of lookup support. Do not
turn a generic decoded file into an invented provider source record, or claim
native picker coverage. Chordie's public text-copy workflow and Wikisource's
separate export service are not covered by this Ozbcoz check.

### HTTP diagnostics and request volume

Live CLI reports add `httpDiagnostics`: actual request counts and HTTP response
status frequencies by host, numeric Retry-After values and database lag, plus
send failures. No paths, query values, headers, credentials or response bodies
are retained. Redirects and retries count as additional HTTP requests; one daily
run is not one request per provider. The existing `rate_limited` reason covers
both HTTP 429 and HTTP 503 for compatibility. Use the exact status counts to
distinguish throttling from service unavailability, and database-lag evidence
where supplied; do not infer that a daily quota was exceeded from that reason.
The local and cloud jobs have separate request totals and reachability.

The transport always identifies Singbook with its version and the public project
URL, including plain Dart maintenance runs without app build defines.
`SINGBOOK_CONTACT_URL` may supply another real operator contact; an empty value
keeps the public project fallback. Wikimedia's 2026 limits apply across projects,
so a short burst against Wikidata can affect subsequent Commons or Wikisource
requests even in a once-daily job. Follow the publisher's
[client identification policy](https://www.mediawiki.org/wiki/Wikimedia_APIs/Access_policy)
and [current rate limits](https://www.mediawiki.org/wiki/Wikimedia_APIs/Rate_limits).
A compliant User-Agent does not remove quotas or replace respecting Retry-After.

SyncLRC's free-text search and its selected-song lookup have different contracts.
App discovery supplies the separate track, artist, album and duration fields to
the documented `/lyrics` route. It validates the returned title/artist and keeps
returned album/duration for the existing recording and edition checks. It never
copies requested context over a different upstream result. Canonical-ID resolve
also rechecks the selected title, artist, album and duration: observed search
rows can share a canonical ID despite differing recording context. Legacy
carried selections remain readable. Channel-2 canaries cover two canonical
retrievals and a separate title-only catalog search with exact expected fields;
canonical-only retrieval does not count as search coverage. A failing search
probe stays visible even when both direct extraction canaries pass. These native lookup
changes require a compatible app build; frozen release artifacts are unchanged.
All SyncLRC routes share a transport floor of 2.1 seconds between attempts,
including retries, to respect the publisher's documented 30 requests/minute.

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

### YouTube Music availability

The YouTube Music probe uses the same anonymous requests as the app, including
the fixed `SOCS=CAI` accept-all marker on exact Music homepage/JSON endpoints.
It does not read a private browser profile, transfer stored cookies, open a
consent flow or sign in. Do not interpret this fixed marker as neutral/reject,
or reuse historical private-session results as proof of current extraction.
Google may still serve a consent interstitial, regional restriction, challenge
or unavailable response; the probe reports that ordinary outcome. Other source probes
continue independently. Run the normal live check or select YouTube Music with
`--source youtubemusic` to record the current result.

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
   Run the opt-in publisher file-import check once as a separate, sequential
   phase when Flutter test dependencies are available. Retain its dated redacted
   report with the health report, including failed/unverified outcomes. Keep its
   runtime and capability provenance separate from the ordinary CLI result. Do
   not repeat the entire live suite to chase an individual unavailable source;
   use a bounded selected-source recheck only when new evidence warrants one.
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
