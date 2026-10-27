# Regional source qualification: TouhouDB and UtaiteDB

The prepared compatible channel-5 runtime registers both native sources. It
complements VocaDB's voice-synth focus and preserves all 24 channel-4 entries.
Public-main integration, a compatible app release, Android UI and cloud
qualification remain separate gates. Catalog totals below do not establish
lyric-bearing counts or incremental coverage.

## Publisher scope and documented interface

[TouhouDB's scope](https://wiki.vocadb.net/docs/touhoudb-what-is-it-for)
includes Touhou-inspired music, arrangements, artists and discographies for
Japanese and international users. The publisher explicitly describes its
accessible API and shared VocaDB infrastructure. Its
[song guidelines](https://wiki.vocadb.net/docs/touhoudb-songs) describe version
relationships, lyric sources/languages and metadata.

[UtaiteDB's scope](https://wiki.vocadb.net/docs/utaitedb-what-is-it-for)
includes human-vocalist originals and arranged versions, related-version links,
and Japanese, Romanized and English names. Its
[song guidelines](https://wiki.vocadb.net/docs/utaitedb-songs) govern those entries.
The publisher's [integration list](https://wiki.vocadb.net/docs/services-that-make-use-of-vocadb-apis)
explicitly lists an automatic tagger using VocaDB, UtaiteDB and TouhouDB.

Both host-specific OpenAPI documents were retrieved successfully at
2026-10-27T10:10:57Z, each 303,621 bytes:

- [TouhouDB OpenAPI](https://touhoudb.com/swagger/v1/swagger.json)
- [UtaiteDB OpenAPI](https://utaitedb.net/swagger/v1/swagger.json)

Both document numeric song IDs, `/api/songs`, `/api/songs/{id}`, aliases,
artist roles, albums, original-version ID, duration, BPM ranges and culture codes.
Optional lyric entries describe ID, translation type, cultures, source credit,
URL and value. Read routes have no declared security requirement. Documentation
availability and similar contracts do not prove identical live detail behavior.

## Bounded local observations

Ordinary TLS-verified requests used an identifying project User-Agent, no account,
cookies or credentials. One count request per host used the documented
`maxResults=1&getTotalCount=true`; optional fields were omitted. Each returned
one metadata row with no lyrics property or body.

| Host and exact request | Measured UTC | HTTP | Unfiltered song-entry total |
| --- | --- | --- | ---: |
| [TouhouDB](https://touhoudb.com/api/songs?maxResults=1&getTotalCount=true) | 2026-10-27T10:15:17.243023Z | 200 | 190,042 |
| [UtaiteDB](https://utaitedb.net/api/songs?maxResults=1&getTotalCount=true) | 2026-10-27T10:15:17.737952Z | 200 | 78,943 |

These totals include versions and instrumental entries. They are not counts of
available lyrics, distinct compositions or songs missing from existing providers.

Four publisher-linked canonical HTML pages also returned HTTP 200 without
redirects. Their small HTML shells exposed title/description metadata:

| Entry | Title and credited artist | Fresh version evidence |
| --- | --- | --- |
| [TouhouDB 12268](https://touhoudb.com/S/12268) | チルノのパーフェクトさんすう教室 / ゴサマル | Fresh metadata does not identify its version class. An indexed publisher page labels it Rearrangement; this is not fresh detail-API evidence. |
| [TouhouDB 194411](https://touhoudb.com/S/194411) | Night dream in the cage (2026 Remaster) / 隣人 feat. 坂上なち | Remaster; published 2026-05-04. |
| [UtaiteDB 94178](https://utaitedb.net/S/94178) | 異星にいこうね / いよわ feat. navi | Cover; published 2026-08-14. |
| [UtaiteDB 63028](https://utaitedb.net/S/63028) | CH4NGE / Giga feat. CircusP | Cover; published 2024-07-15. |

Those six local requests ran from 10:15:17Z through 10:15:18Z: all HTTP 200, zero
retries or denials. Earlier homepage, linked API-configuration and documentation
checks were separate requests and are not included in that six-request count.
No lyric-body API, audio, video, artwork or corpus download was performed.

## Access, attribution and next qualification

The shared [API guidance](https://wiki.vocadb.net/docs/public-api) asks clients
to identify themselves, cache responses and avoid excessive traffic.
The shared [license](https://wiki.vocadb.net/docs/license) covers database
metadata with attribution/link-back and expressly excludes uploaded images and
lyrics. The initial small HTML shells exposed no attribution links. A subsequent
anonymous rendered-page check found that **both hosts themselves** link their
footer's Creative Commons notice to `https://wiki.vocadb.net/wiki/29/license`,
which resolves to that shared license page. Its linked terms provide the service
as-is without availability or accuracy guarantees. No account or terms-acceptance
action was needed. Do not claim a general license to underlying lyrics or artwork
from the metadata/database license; each original lyric's supplied source credit
and URL stay in the retained source facts.

## Native extraction and compatible catalog

`VocaDbProvider`, `TouhouDbProvider` and `UtaiteDbProvider` share a bounded parser
with three private fixed host/identity presets. There is no caller-selected host
or downloaded code. Each source has its own ID, attribution, source-fact key,
parser identity and mutable cache. Existing VocaDB constructor options and source
JSON fields remain compatible. Successful documents retain their actual
retrieval timestamp in a 32-entry, 15-minute cache. Requests serialize at one
second per provider, in addition to ordinary transport pacing.

Initial cover/remaster detail checks returned no lyrics. The four lyric-bearing
canaries below were identified through those responses' explicit version links;
the adapter never follows those links to fill a cover's empty lyric body.
Entries remain source arrangements with empty recording IDs. Multiple originals
are ambiguous; no original is unavailable, rather than an English-translation
fallback. Original and translated variants remain distinct source facts.

| Native canary | Artist | Selected original / retained variants |
| --- | --- | --- |
| [TouhouDB 138](https://touhoudb.com/S/138), Cirno's Perfect Math Class | ARM, IOSYS feat. miko | 17 / 2 |
| [TouhouDB 51766](https://touhoudb.com/S/51766), Night dream in the cage | Linjin feat. Sakaue Nachi | 15699 / 1 |
| [UtaiteDB 72011](https://utaitedb.net/S/72011), Take you to an alien | Iyowa feat. SEKAI | 15343 / 1 |
| [UtaiteDB 51300](https://utaitedb.net/S/51300), CH4NGE | Giga feat. KAFU | 10454 / 1 |

At 10:45:53Z–10:46:01Z on 2026-10-27, the first three contextual search/detail
canaries passed through the native adapters and ordinary matching service. The
fourth search did not contain its known ID: twelve highly rated covers crowded
out the original. That first attempt used seven HTTP 200 responses, no retries
or network failures. Metadata-only diagnostics confirmed that the documented
`Exact` name match with `Name` sorting includes the exact original.

Contextual lookup now uses the ordinary title-only `Auto`/`RatingScore` search
first, then at most one same-title `Exact`/`Name` search when no row satisfies the
full artist/alias/album/duration context. Each response remains capped at twelve;
there is no pagination, count query or fallback after an access/parse failure.
Ordinary free-text search remains unchanged. The affected CH4NGE contextual
lookup passed at 10:56:42Z–10:56:45Z with three HTTP 200 responses and no retries
or failures; the other three successful canaries were not repeated for that fix.
CH4NGE is a direct canonical CLI canary plus this separate contextual-app check;
its ordinary first free-text page is not claimed to contain the original.

All four retained full variant credits, aliases, artist roles, album arrays,
culture codes, web links, original-version IDs and raw JSON. Actual native
snapshots also passed an offline AppController save, native SQLite reopen and
ChordPro round trip. Every source field and original source body remained exact;
the combined document can add normal inferred section markup while preserving
its lyric order. Saved song JSON and hashes survived reopening. A separate
offline replay of the two previous real VocaDB canaries preserved its existing
candidate, body, metadata, attribution and every extra field.

The channel-5 bundle/URL/cache use revision 16 and `sourceCatalog:v5`, leaving
all older catalogs and cache streams unchanged. Existing opt-outs win, including
saved choices for either new source. No new release version is allocated here.

Before production availability:

1. Complete final registered-runtime CLI and hosted checks on the committed
   candidate; retain precise timestamps and request/code provenance.
2. Verify Android search/detail/save and offline readers with data preservation.
3. Integrate through the public-main owner, verify the served compatible catalog
   and release/install a new compatible app. Older released clients retain their
   existing catalogs and cannot gain native providers through configuration alone.
4. Probe the actual managed-cloud runtime separately. Local success, synthetic
   fixtures and hosted compilation do not establish cloud API reachability.
