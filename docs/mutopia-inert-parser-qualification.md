# Mutopia literal-source qualification

This is candidate parser and search-contract evidence. No Mutopia provider is
registered, catalog channel changed, or source enabled by this work.

The reader accepts a bounded literal subset of LilyPond: root metadata, named
lyric-mode streams, quoted syllables, word continuations, melismas and literal
bar-number checks. It never evaluates Scheme, includes, context expansion or
LilyPond. Unsupported lyric constructions reject the document. Limits are
524,288 source string code units, 100,000 tokens, depth 128, 32 streams and
131,072 reconstructed lyric string code units.

Separate streams retain publisher variable names and source spans. A literal
`lyricsto` reference does not prove that a stream is active or printed; the
parser always reports `attachmentVerified: false`. Variable names are not
verified language tags. Source line breaks are not poetic or timing boundaries.

## Retained source assessment

Two secular editions fetched on 2026-10-29 were reassessed locally without
additional HTTP calls. Both detail pages and source headers declare Public
Domain for the edition; preserve this publisher declaration and attribution
separately from any recording rights.

| Edition | Publisher title | Literal streams | Original source SHA-256 |
| --- | --- | --- | --- |
| [2244](https://www.mutopiaproject.org/cgibin/piece-info.cgi?id=2244) | Notte e giorno (Don Giovanni) | 2 | `a4528c885c201f7e5408c6e1d2873372a97f020cc0b3fa3809f0c4e02caf5541` |
| [2243](https://www.mutopiaproject.org/cgibin/piece-info.cgi?id=2243) | What power art thou (King Arthur) | 1 | `79ab4ad4c8daaf170432629653cbd8b1d3b840a8ecf5cbf6369b2a700953e8b4` |

The current reader reconstructs all three literal streams. Twelve synthetic
regression tests cover supported tokens, identity of distinct streams, literal
metadata scope, unsupported/dynamic grammar and resource bounds. An independent
lyric oracle, active score attachment and whole-catalog coverage are unverified.
The files contain no explicit chord-mode block; piano parts do not prove chord
chart coverage. The site's total score count is not a lyric/chord count.

## Search contract follow-up

The publisher's retained GET form establishes `make-table.cgi?searchingfor=...`.
On 2026-10-30T03:21:24Z–03:21:29Z, three ordinary local anonymous GETs returned
200 without redirects or retries: the two titles above and a deliberately
unmatched query. Original response bytes are retained privately with hashes.
These are search-page access checks, not a completed search-result parser or
full live extraction canaries.

Before registration, qualify result selectors, paging, duplicate/empty/error
behavior and strict edition identity. The existing single-body result model
also needs an explicit stream identity/selection path so translations and
parallel underlays remain separate. Preserve composer, poet and arranger roles
without inventing a performer, recording ID, language, chord chart or timing.
Two native extraction/import/persistence/export canaries, edition attribution
and license checks, compatible app/catalog integration and actual cloud
qualification remain required.

Primary contracts: [Mutopia reuse terms](https://www.mutopiaproject.org/legal.html),
[publisher source fields](https://www.mutopiaproject.org/contribute.html), and
[LilyPond lyric notation](https://lilypond.org/doc/v2.24/Documentation/notation/common-notation-for-vocal-music).
