# Regional source leads: TouhouDB and UtaiteDB

These are new discovery candidates, not registered providers or extraction
qualifications. They complement the prepared VocaDB adapter's voice-synth focus.
No released app, cloud reachability, lyric-bearing count or incremental coverage
is established by this investigation.

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
lyrics. That page names VocaDB. The returned TouhouDB/UtaiteDB HTML shells exposed
no license/attribution links, so host-specific applicability still needs a
rendered-page check. Failure to see a link in a shell is not proof it is absent
from the rendered site. Do not claim a general license to underlying lyrics or
artwork from a metadata/database license.

Before activation:

1. Verify each host's rendered attribution/license destinations and intended app
   use, retaining per-lyric source credits and any unresolved rights distinction.
2. Compare actual version/detail responses with the host-specific OpenAPI. A
   source version ID stays scoped to its provider/host; it is not an ISRC or a
   confirmed recording identity. Covers, rearrangements and remasters retain
   their exact credits and original-version relationships.
3. Select two independent lyric-bearing canonical entries per source and run
   bounded search/detail canaries. The four HTML leads above are not passed
   extraction canaries and may lack a usable unique original lyric variant.
4. Preserve every lyric variant, credit, alias, artist role and album fact;
   distinguish original lyrics from translations and romanizations. Reuse any
   VocaDB extraction code only after these actual-response checks.
5. Qualify compatible source registration/catalog caching, controller save,
   SQLite/ChordPro retention, Android UI and actual cloud reachability. Keep
   native additions in a compatible new runtime/channel, preserving older
   app catalogs, saved preferences and source IDs.
