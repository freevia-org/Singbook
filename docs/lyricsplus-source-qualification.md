# LyricsPlus native candidate qualification

This native candidate is compiled into the provider registry, with no catalog
or release activation. Older catalog channels keep their exact source rosters.
The dedicated 28-case offline suite, 1,461 combined provider/domain/controller
tests and scoped analysis pass on the isolated native branch. Two independent
live adapter canaries also pass; integration on the latest main and app release
gates remain explicit below.

## Access and observed schema

Primary API contract:

- https://github.com/ibratabian17/LyricsPlus/blob/gelato/docs/endpoints.md
- https://lyricsplus.prjktla.my.id/openapi.yaml
- Published service implementation reviewed at Git blob
  `7b9c7086d2ec84c67b86cf893a5e0ca5f33b6e36` (`internal/service/service.go`).

The documented anonymous routes are `/v1/songlist/search?q=...` and
`/v2/lyrics/get?title=...&artist=...`. Ordinary service caching is retained;
the adapter never submits forceReload, cookies, credentials or proxy mirrors.
Requests use the existing bounded ProviderTransport and its host pacing.
Selected source documents and independent metadata have bounded memory caches.

Two research searches and two V2 reads on 2026-10-27 returned HTTP 200. Those
were schema research, not proof that this new native adapter has passed live
qualification. Raw lyric payloads remain in ignored private artifacts.

## Catalog identity and the real album conflict

Search aggregates heterogeneous upstream catalogs. Exact normalized title/artist
rows form a provider-local lyric lookup identity; this does not invent a
recording ID. Every original catalog row remains provenance, including album,
ISRC, source IDs, artwork and unknown extension fields. These fields are lookup
hints, not facts about the as-yet-unresolved lyric winner.

V2 selectedSongMetadata can be populated from request hints on cache hits.
Therefore matching echoed title, artist, album, duration or ISRC alone is
insufficient recording evidence. Resolve submits title/artist only. Initially,
only Apple winners with a returned numeric platform ID are supported. That ID
must resolve independently through the official Apple iTunes lookup API; the
returned title/artist and explicit edition constraints must agree. Apple IDs
are retained as attributed source metadata, never promoted to recordingIds.

The real research negative case is Billie Jean. The searched Deezer row was
Michael Jackson's This Is It, whereas returned Apple ID 1883770432 independently
identifies Michael: Songs From The Motion Picture, 294237 ms. A single official
Apple lookup on 2026-10-27 validated that ID and Creep's ID 1097862231 (Pablo
Honey, 238640 ms). The adapter exposes the independently returned Apple album
and retains the different catalog album as provenance. It does not claim that
the lyric came from the selected Deezer recording or echo its ISRC as proof.
An explicitly constrained, conflicting album or edition is rejected.

Results remain arrangement-scoped and unverified until normal app matching.
The source timeline is retained without an audio-alignment or recording claim.
Unknown winners, absent IDs and contradictory independently verified identities
fail explicitly; unsupported sources are not silently interpreted as Apple.

## V2 timing and data retention

The dedicated profile reads absolute integer milliseconds for line and word
starts and durations. It preserves overlaps, individual occurrences, singer and
part metadata, background/synthetic flags, translations, transliterations,
unknown extensions and original JSON bytes. Word spans use Unicode grapheme
indices. Segment text must exactly reconstruct the source line; invalid units,
out-of-range times, impossible duration or mismatched text are rejected rather
than replaced with invented timing. Line-only payloads remain line-only.
Main and background words retain their source text offsets and are ordered
within their own layer: background words may follow main text while starting
earlier. Chronological portable cues preserve both layers and their original
occurrence IDs. A backwards start within either layer remains invalid, and
background flags must be boolean before they can select a layer.
The documented None type retains plain lyrics and raw JSON with no fabricated
cues; its timing track is explicitly unsupported rather than playable.

The observed Billie and Creep documents contained 61/38 lines and 488/190 word
segments, respectively. All segment concatenations matched their line text;
Billie contained five overlapping line pairs. Synthetic unit fixtures contain
no copied source lyrics. API code licensing does not establish per-work lyric
rights; attribution and unknown underlying rights are preserved.

## Outstanding gates

On 2026-10-27 at 16:54 UTC, ordinary native search/resolve plus independent
Apple lookups passed for Billie Jean and Creep: six HTTP 200 responses, no
retries, network failures, cookies, credentials or forceReload. The returned
Apple IDs were 1883770432 and 1097862231. The first returned its actual motion
picture album, preserving the different catalog album as a hint. The parser
retained 549/228 cues (61/38 lines plus 488/190 word segments), with timing
explicitly unverified. Both source payloads survived ChordPro round trips
exactly. This establishes local adapter extraction, not app or cloud behavior.

The first selected live attempt returned three HTTP 200 responses but exposed
valid background-word interleaving rejected by the parser. That was reproduced
and fixed offline from retained data, with four synthetic regression cases,
before one justified two-canary rerun. No full-registry live run was repeated.

Recheck affected integration paths after updating to the latest public main.
Confirm app search/import/save/reopen and ChordPro provenance/timing round trips.
Cloud reachability remains untested. Source-specific support beyond Apple
winners requires its own returned-identity and timing evidence. No activation,
catalog revision, compatible release or public-main publication is claimed.
