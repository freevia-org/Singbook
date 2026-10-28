# Source discovery review — 2026-10-27

This review adds evidence and decisions only. No adapter, catalog entry,
release, credentials or user library is changed. The current main baseline has
39 discovery records; this PR retains all39 and adds six unique deferred
candidates, for45 total. LyricsPlus native work is already tracked separately
in PR191.

| Candidate | Evidence and decision |
| --- | --- |
| Jamendo | Its [track API](https://developer.jamendo.com/v3.0/tracks) documents optional lyrics, metadata and artwork. [Authentication](https://developer.jamendo.com/v3.0/authentication) requires an app client ID. [API terms §3.3](https://devportal.jamendo.com/api_terms_of_use) restrict offline-focused applications, so defer rather than use the public test credential as production access. No content API request or account registration was made. |
| Audius | Its [API](https://docs.audius.co/api/) documents anonymous reads. Three JSON requests returned 200: trending limit2 and exact details for two returned IDs. Both expose artwork and metadata; these two details have no lyrics/chords or album name. Uploaders and collaborators must remain distinct from recording artists. Defer cross-recording enrichment until identity/role handling and app qualification are explicit. No audio, image or download request was made. |
| Ozbcoz native search | [Publisher Help](https://ozbcoz.com/myfaq/doku.php/chordpro_index) documents ChordPro downloads for other song apps. The existing file route has passed both host and Android picker import/reopen/export. New local index requests returned403 with both the default client and actual Singbook identification; the latter contained a browser challenge. Automatic search remains deferred; no cookies, challenge workaround or source retirement. [Terms](https://ozbcoz.com/terms) retain per-song rights uncertainty. |
| Karalyr | The [documented public API](https://www.karalyr.com/docs) offers word lyrics and separate machine-detected chord segments with confidence. Its [homepage](https://www.karalyr.com/) reports52 songs, so it is an emerging small source. No content endpoint was called. Defer until value, identity, revision/chord semantics, live canaries and app persistence are qualified. Its [rights page](https://www.karalyr.com/takedown) separates contributed content rights from the software license. |
| music-utils | Its [publisher API documentation](https://github.com/sillygru/music-utils/blob/main/API.md) offers keyless metadata/artwork with upstream provenance and instance-local IDs. Two distinct identified metadata canaries returned530 edge pages, so extraction and availability remain unverified. No retry, lyric, image, audio or additional endpoint request was made. |
| Pisni.org.ua | [Publisher statistics](https://www.pisni.org.ua/page.php?chapter=stats) report55,929 songs and2,873 chord-bearing entries; these are not independently enumerated or necessarily synchronized totals. Homepage, two song pages and one observed form search returned200. Offline inspection proved exact Windows-1251 byte round trips and isolated `pre.songwords` bodies. Regional H/B notation and multiple performer/writer/composer roles require native qualification; the source is deferred, with no remote catalog activation. [Participation rules](https://www.pisni.org.ua/articles/34.html) require source/author information but do not establish a blanket reuse license. |

The follow-up made eight direct HTTP requests: two Ozbcoz index checks, two
distinct music-utils metadata queries, and four Pisni page/form requests. No
transport retry, production suite, credential/session, media or user-library
operation was used. Web documentation reads are separate from those counts.
Original source pages stay private; sanitized evidence contains status, hashes,
encoding/field observations and unresolved gates rather than lyrics.

Scope reconciliation: the preserved19:04Z regional receipt covers four new
records (Ozbcoz, Karalyr, music-utils and Pisni) and the eight direct HTTP
requests listed above. Jamendo and Audius are separate discovery evidence in
the table; they are not covered by that receipt or its request count. The
receipt's `all41PriorDiscoveryRecordsUnchanged` field is inaccurate: its pinned
source commit `de7e236fd534a58201a64963c65653973300a8ba` has39 discovery
records. The updated PR config is based on those exact39 current-main records
plus the six unique deferred additions (45 total). The immutable receipt is
preserved unchanged; its four-source count must not be read as validation of
all six PR additions.

Pisni is the next promising regional integration candidate. Its native contract
must decode the declared Windows-1251 bytes and encode the observed search form
correctly, retain exact original bytes/notation, separate composer/writer from
listed performers, preserve arrangement scope without fabricated recording IDs,
and qualify chord placement/notation before save/reopen/export and app tests.
Unknown/native grammar must not be activated through an older served channel.

The separate production local maintenance measurement uses public main
`0e60375bdece0afe21a4fa9b307eadc84022379b`, its ordinary channel6 default,
revision18. The offline registry/catalog check passes before HTTP. One full
live run measured all27 sources:19 healthy,2 transient errors,2 unavailable,
2 partial coverage,1 import-only and1 retired. Its92 HTTP attempts include
ordinary bounded retries; one send timed out. No full live rerun was made.

Genius timed out after an API200, rather than rejecting a credential. LRCLIB
returned five503 responses with Retry-After1 and three200s; MusicBrainz
recovered from one503 and passed. These status codes and counts do not prove
a daily quota or excessive scheduling. SyncLRC's two canonical lyric probes
passed while catalog search was empty. BetterLyrics refused the selected
canary with401. Chordie/Wikisource search and extraction passed; file-import
coverage remains separate. The Ozbcoz opt-in host import phase has its own
runtime, timestamp and request accounting and is not inferred from this CLI.

The latest available cloud evidence is separately dated2026-10-26 at23:11UTC,
channel2 revision11 with22 entries. It cannot establish cloud coverage for
the six deferred candidates in this PR. Local results do not replace cloud evidence.

## 2026-10-28 documentation-only additions

The incoming draft at `df651b9d58e658d4754117dac87a982401f207c3` contains
46 records, including the separately recorded LiederNet lead. The earlier
45-record totals above describe the previous stage and are preserved as dated
evidence. This append adds five unique deferred records for **51 total**.
All 46 existing records, their order and facts, and the existing document text
remain unchanged. These research leads establish no current app availability,
verified lyric/chord coverage or blanket content permission.

| Candidate | Evidence and remaining qualification |
| --- | --- |
| Digital Tradition / Mudcat | [Publisher rules](https://mudcat.org/DigiTrad-rules.cfm) encourage database copying while retaining individual song copyright limits. The 7,800-song count is explicitly April 1999. [Current download documentation](https://mudcat.org/download.cfm) lists Spring 2002 packages; no archive or program was downloaded or executed. [Search documentation](https://mudcat.org/DigitradSearch.cfm) describes title/keyword/category and ballad searches. Current bounded extraction, per-item provenance/rights, identities and two canaries remain unqualified. |
| Dutch Song Database | [Publisher homepage evidence](https://www.liederenbank.nl/) describes over 180,000 archival song descriptions; only some link complete text, melody or audio. This does not count full-lyric imports or unique recordings. Live homepage and [MTC documentation](https://www.liederenbank.nl/mtc/) reads returned 403 and were stopped. Cached MTC research-collection licensing and [archival collection 313](https://flat.meertens.knaw.nl/flat/islandora/object/lat%3A10744_c961bb4f_3169_4c68_a974_93501ff9e985) access restrictions have separate scopes. Neither establishes the whole database's app-access or reuse contract. |
| The Session | [Publisher-maintained data license](https://github.com/adactio/TheSession-data/blob/main/LICENSE.md) includes an LLM-processing restriction with a narrow accessibility exception, alongside database-license provisions. The [API documentation](https://thesession.org/api) returned 403. No tune data, corpus, content transformation or extraction canary was requested. Defer this assistant-based qualification until an applicable permitted route and the remaining source contract are established. |
| Śpiewnik Wywroty | [Publisher terms](https://spiewnik.wywrota.pl/blog/zasady-i-warunki) require prior administrator permission for automated access/extraction and reserve text/data-mining rights. No content extraction, alternative endpoint, account or outreach was attempted. Machine access, app persistence/export, identity and two canaries remain unqualified. |
| fanart.tv | [API documentation](https://api.fanart.tv/) describes artist and album artwork using artist MBIDs and release-group MBIDs. A release-group image does not prove an exact-release cover. Its [developer key process](https://fanart.tv/get-an-api-key/) is distinct from personal keys; no credential was obtained or API/image request made. Per-image copyright can be unknown. Production key provisioning, intended offline/export use, attribution, exact identity and two asset-retention canaries remain unqualified. |

These are documentation-only decisions. Publisher documentation reads and
failures are distinct from source extraction or asset calls; no new extraction
canary, source adapter, registry/catalog activation, cloud, release or Publishing
operation is part of this append. The two redacted source packets remain on
`codex/datasource-health`:

- `reports/source-maintenance/local/qualifications/2026-10-28T065930Z-discovery/discovery-decisions.json`
  (SHA-256 `22c44aebecebe8b6dc386fc1e5ff9ce2d7c15c932b5d935c5ee95e5889a48215`).
- `reports/source-maintenance/local/qualifications/2026-10-28T115914Z-discovery/discovery-decisions.json`
  (SHA-256 `39d00e1887b8218ebe06bba47c1410847b9519d5b1aee345b0a38afd9fd9229e`).
