# Mutopia literal-source qualification

This is candidate source and application-flow evidence. `MutopiaProvider` is
implemented but not registered; no catalog channel changes or source activation
are included. Native app and managed-cloud qualification remain pending.

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

The current reader reconstructs all three literal streams. Synthetic regression
tests cover supported tokens, identity of distinct streams, literal metadata
scope, unsupported/dynamic grammar and resource bounds. An independent
lyric oracle, active score attachment and whole-catalog coverage are unverified.
The files contain no explicit chord-mode block; piano parts do not prove chord
chart coverage. The site's total score count is not a lyric/chord count.

## Search contract follow-up

The publisher's retained GET form establishes `make-table.cgi?searchingfor=...`.
On 2026-10-30T03:21:24Z–03:21:29Z, three ordinary local anonymous GETs returned
200 without redirects or retries: the two titles above and a deliberately
unmatched query. Original response bytes are retained privately with hashes.
These three requests were search-page access checks, counted separately from
the full source canaries below.

## Source and application follow-up

The adapter parses the observed five-row search tables, an explicit empty-result
alert, canonical numeric detail IDs and canonical linked source URLs. It checks
edition identity and publisher-declared Public Domain against both source and
detail metadata. Search examines at most 64 result tables and downloads at most
three source files, prioritizing explicit vocal listings. Blank lyric streams
are skipped. Unsupported lyric grammar fails extraction. Paging and broad mixed
instrumental/vocal queries remain unqualified; an unsupported file may prevent
the bounded query from returning otherwise supported results.

On 2026-10-30T04:29:59Z–04:30:09Z, two full local anonymous search/resolve
canaries issued eight GETs, all HTTP 200, with zero retries. Edition 2244 yielded
two distinct stream candidates and resolved `englishLyrics`; edition 2243
resolved `text`. Original source hashes matched the retained files above.
An additional current-code replay at 05:04Z used zero network requests and
eleven mock transport requests over retained real responses, reconstructing
all three streams with unchanged body and payload hashes. Search and resolve
currently fetch source text separately; these counts are not daily scheduling
frequency or cloud reachability evidence.

Each candidate uses `editionId:publisherVariable`, preserves the variable as a
source text label and keeps translations/underlays separate. Composer, poet,
arranger, source citation, edition attribution, raw response bytes and all
sibling streams remain available. Composer is explicitly a composer credit;
no performer, recording ID, language, key, tempo, chord chart or timing is
inferred. Literal source text is escaped when represented as ChordPro.

Search, preview, version selection and saved rows expose the selected publisher
text label. A deterministic version descriptor prevents the comparison engine
from borrowing a sibling stream's body. Saving a preferred sibling preserves
the same edition's library entry, source archive and previous saved versions;
reopening comparison and restoring the archived text preserve its own selected
reference. Separate score editions and performer recordings do not match merely
on title/composer. Pending Mutopia matches cannot be saved. The descriptor is a
consistency marker, not an authenticity signature.

Validation: 98 focused provider, parser, controller, persistence, identity,
grouping and widget tests passed; analysis of 17 changed Dart files was clean.
Six additional visual tests passed, with fresh compact, large-text, RTL/dark,
landscape and Ukrainian/dark captures reviewed. The controller flow uses
synthetic source fixtures with real SQLite/ChordPro persistence; it does not
replace native live evidence. Two native extraction/import/persistence/export
canaries, compatible app/catalog integration, exact-head CI and actual managed
cloud qualification remain required before activation. Older catalog channels
and production health reports are unchanged.

Primary contracts: [Mutopia reuse terms](https://www.mutopiaproject.org/legal.html),
[publisher source fields](https://www.mutopiaproject.org/contribute.html), and
[LilyPond lyric notation](https://lilypond.org/doc/v2.24/Documentation/notation/common-notation-for-vocal-music).
