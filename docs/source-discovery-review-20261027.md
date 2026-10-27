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
