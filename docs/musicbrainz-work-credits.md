# MusicBrainz linked-work credits

The previous recording lookup requested `work-rels` but did not request the
linked works' artist relationships. As a result, composer, lyricist and writer
credits could be absent even when the publisher held them. The expanded lookup
adds `artist-rels` and `work-level-rels` to the same recording GET, following the
[publisher's relationship include contract](https://musicbrainz.org/doc/MusicBrainz_API#Relationships).
No additional work/artist searches, authentication or normal lookup requests
are introduced. Existing pacing, cancellation and optional artwork rules remain.

`musicbrainzWorks` preserves bounded work IDs/titles, ISWCs, languages,
association type/direction/attributes and structured artist-role credits. Each
credit keeps its artist MBID and role; recording performers and technical roles
are not turned into work authors. Counts expose omitted/truncated artist rows.
Malformed, multiple, differently titled, partial or medley associations retain
scoped facts without donating flat authorship. Flat `credits`, `writers`,
`composers` and `lyricists` require a single valid, complete, same-title work
linked by a forward performance relationship with no extra attributes. Only
explicit backward writer/composer/lyricist artist relationships without extra
attributes are eligible. Names, IDs, role directions and recording identity
remain distinct; no key, tempo or timing is inferred.

These relationships are [MusicBrainz core metadata](https://musicbrainz.org/doc/MusicBrainz_Database)
under CC0. This change does not request community genre associations, tags or
ratings, whose supplementary-data terms differ. Existing MusicBrainz attribution,
field-specific source rights and artwork rights remain separate.

On 29 October 2026, two selected field-discovery GETs returned HTTP 200 without
retries. After implementation, two ordinary native-provider canaries returned
HTTP 200 at 14:30 UTC: Mysterons / Portishead and Colors and the Kids / Cat Power.
They retained three/one work writers with exact artist and work IDs. Independent
checks against the returned relationships passed; writers reached the combined
document, and all source metadata survived ChordPro export/import. Authored
lyric placeholders exercised combination without publishing source lyrics or
claiming independent transcription accuracy. No artwork/media, credential,
user-library or full daily-suite request was made. Total live requests for this
new capability: two discovery plus two qualification recording GETs.

A subsequent malformed-sibling guard is qualified against those retained bytes
without repeating live requests. Its exact source hashes and replay scope are
recorded separately from the earlier live receipt. Synthetic regressions cover
ambiguous associations, wrong directions/types, malformed IDs/attributes,
truncation, combined metadata and portable source rights. Existing MusicBrainz
artist-context, song-donor and artwork regressions remain relevant.

This is a compatible compiled-adapter improvement; an app update is required.
Registry/catalog/cache channels, defaults, schedules and release artifacts are
unchanged. It is a review candidate, not an integrated or installed release.
