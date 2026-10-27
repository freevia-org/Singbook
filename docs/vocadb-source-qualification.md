# VocaDB source qualification

VocaDB is a new candidate for voice-synth song coverage, including Japanese and
English originals. Its [public API](https://wiki.vocadb.net/docs/public-api)
allows anonymous HTTPS JSON reads, asks clients to identify themselves and cache
responses, and prohibits excessive unapproved traffic. Its publisher's
[2024 retrospective](https://blog.vocadb.net/blog/new-year-2025) reports 148,860
song additions that year. This is evidence of a substantial database, not a
current song/lyric total or a measured incremental catalog for Singbook.

The [license](https://wiki.vocadb.net/docs/license) covers database metadata under
CC BY 4.0 with attribution and a link back. It explicitly excludes third-party
lyrics, uploaded images and audio. The adapter retains that distinction, the
original response and lyric-specific source credits. It fetches no artwork,
audio or video and makes no redistribution-rights claim for lyric text.

## Native adapter

`VocaDbProvider` uses the documented `/api/songs` and `/api/songs/{id}` routes,
with bounded optional fields and English display names. Search requests at most
12 results with the documented `RatingScore` sort and skips the extra count
query. Default name sorting placed unrelated versions ahead of both known
canaries in an initial five-row diagnostic; sorting is not permission to choose
the first result. Every qualification selects the exact publisher-linked ID.
Context lookup searches the title alone, checks the full artist credit and any
specified album/duration against structured search rows, and leaves the service's
independent identity checks intact. Search includes album records for this
purpose. Cached rows are reusable only when the added context still matches.
The methods follow PR173's interface contract; that interface is deliberately
not duplicated in this independent branch and must be wired after integration.

The source ID identifies a VocaDB song/version. It does not become an ISRC or
confirmed recording ID. The original/cover/remix classification stays attached
to that entry. The candidate keeps its complete title aliases, artist roles,
album records and culture codes. Distinct album titles do not become an
arbitrary first album. Only explicitly declared Composer/Lyricist roles become
those metadata fields; default vocalist or illustrator roles do not. A fixed
milli-BPM value becomes tempo; a range remains a source-specific range.

The lyric response may include originals, romanizations and translations in any
order. Exactly one original is required for the primary body. Every variant,
its ID, culture codes, source credit and URL is retained separately in the source
facts and original JSON. No original is unavailable; multiple originals are
ambiguous. Neither condition silently substitutes an English translation.
Plain text is escaped before ChordPro parsing and cannot inject local extensions.

Requests are serialized at one second per adapter, on top of ordinary transport
pacing and restrictions. Successful detail responses have a bounded 32-entry,
15-minute in-memory cache; they are mutable records, not immutable documents.
Cache hits preserve the real retrieval timestamp and recheck selection identity,
album, duration and cancellation. Failed access/extraction does not replace a
successful cached entry. No cookies, credentials or alternative hosts are used.

## Live evidence

The production native adapter and ordinary matching service passed two bounded
search/detail canaries locally at 2026-10-27T08:48:38Z. Four HTTP 200 responses,
zero retries and zero network failures were observed:

| Publisher identity | Extracted facts |
| --- | --- |
| [1501, Rollin' Girl](https://vocadb.net/S/1501), wowaka feat. Hatsune Miku | Japanese original 97; four lyric variants, five names, three artist-role records, seven album entries, fixed 195 BPM. |
| [68814, ECHO](https://vocadb.net/S/68814), Crusher, CIRCRUSH feat. V3 GUMI (English) | English original 13309; two lyric variants, one name, six artist-role records, no album, fixed 140 BPM. |

Both exact identities occurred once in their respective bounded searches and
resolved as the same song, with empty recording IDs and no timing tracks. All
names, artist roles, album records and lyric variants matched the original JSON.
The private source snapshots are ignored artifacts; neither the responses nor
lyric text belong in a report or repository fixture. The synthetic regression
fixtures exercise selection order, identity, attribution, cache expiration,
cancellation, malformed/lifecycle responses and extension escaping.

Nine focused regressions cover the adapter, including title-only context lookup
and cache reuse after artist/album context changes. Offline replay of two real native results
through the normal AppController, disposable native SQLite and ChordPro codec
also passed. Both saved song JSONs and hashes survived reopening exactly; every
source JSON field, lyric variant and source credit survived export/import. This
host replay made no new HTTP calls and accessed no user library or device.

This is native extraction qualification, not an activated app source. Registry,
catalog-channel compatibility, wiring through the shared contextual-search
interface, ordinary app bootstrap, Android UI, hosted checks, cloud reachability
and a compatible published app remain required.
Do not add this unknown native ID to either released catalog channel. This work
does not change the already qualified AMLL/SyncLRC stack or frozen release 39.
Independent transcription, audio alignment and overlap with existing sources
are unverified. Multilingual variant retention is not a claim that every song
has those languages or that Singbook has a translated-lyric selection UI.
