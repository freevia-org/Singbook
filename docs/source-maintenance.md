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

Reports include timestamp, source/probe IDs, outcome, missing field names,
lengths/counts and metadata field names. They contain no full lyrics, raw source
documents or credentials. The normalized SourceResult JSON is round-tripped to
check model compatibility and raw timing retention. Live issues return exit 1;
invalid configuration/arguments or file errors return exit 2. Exit 0 in offline
mode means only that static validation succeeded.

Genius uses `GENIUS_ACCESS_TOKEN` from the environment or ignored
`config/local.defines.json`; missing credentials produce `not_configured`.
Windows probes use the test-only curl transport to handle HTTP Early Hints;
mobile lookup continues to use Cronet/NSURLSession. Every probe has a bounded
deadline and cancellation, and transport retries/pacing still apply.

## Daily repair and discovery procedure

The daily Codex automation attached to the Datasources chat runs at 09:00
Europe/Kyiv. It uses this procedure, rather than treating an HTTP 200 as proof
that extraction still works. Like other local Codex scheduled work, it needs the
computer and Codex app running (see [scheduled tasks documentation](https://learn.chatgpt.com/docs/automations?surface=app)).

1. Inspect Git state, current public history, this guide, catalog and previous
   local reports. Use the clean-public-history datasource worktree and preserve
   unfinished changes. Coordinate shared files and device/build ownership.
2. Run all live probes against the current catalog, writing a dated report under
   ignored `artifacts/source-maintenance/`. Compare with prior reports so an
   unchanged failure is not repeatedly announced. A missing credential is a
   coverage limitation, never a schema repair or a healthy source.
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
8. Commit only owned, validated changes on clean public history and hand the
   exact base/head, file list and evidence to Singbook's integration chat. Its
   existing integration process reviews/pushes public `main`; verify the served
   catalog matches the integrated revision before calling an update published.
   Never push old canonical history, publish app-store builds, overwrite secrets,
   clear user data or force-push as part of maintenance.

Stay quiet while source state is unchanged or no actionable candidate exists.
Notify for a validated repair/addition/retirement, publication, newly actionable
failure or required input. Record unresolved issues honestly; automation is a
maintenance loop, not a promise that every inaccessible upstream can be repaired.
