# Pisni native candidate

Pisni.org.ua offers Ukrainian song texts, preformatted chords and source
credits. This native module is preparation only: it is not registered in the
factory, catalog, app defaults or any served channel. Compatible registration,
catalog qualification and app/cloud checks remain separate integration gates.

## Contract and identity

The publisher's observed search form uses Windows-1251, `GET /search.php`,
`phrase` and `obj=s`, with a 20-character input limit. The adapter encodes that
legacy form explicitly and uses a broad prefix for longer input; source IDs and
complete titles remain independent of the lookup hint. Search retains at most
12 distinct document IDs and separates the editorial `.smcont` text from the
actual title. Fragment links, foreign hosts, queries and malformed IDs are not
source identities.

Resolve reads the selected fixed-host `/songs/<id>.html`, validates the
publisher's canonical page-address footer and exactly one `h1`/`pre.songwords`
pair. Exact HTTP bytes and decoded original preformatted text are retained.
Windows-1251 decoding has no lossy UTF-8 fallback; changed/undefined charsets
fail explicitly. The byte, header, body, credit, performer and cache bounds are
finite. No credentials, browser, consent, cookies or media download are used.

The source is a shared arrangement document. The default document artist is
unknown; writer/composer roles are not performers. Contextual lookup can bind
one explicitly linked publisher-listed performer after validating the actual
page. It checks at most three exact-title documents and stops at the first
matching association. It never creates recording IDs or donates a performer's
associated album as the arrangement's recording album. Unlinked credit text,
row-local performer/album relationships and formal roles remain source facts.

The bounded `#songdatablock` metadata parser preserves allowlisted source
notes, keywords, composition information and reference links separately from
the selected lyric text. Alternate preformatted blocks in that source section
remain separate variant facts. Discussion, uploader account details and media
performers do not become canonical song credits. A specifically labelled chord
arranger name is preserved without importing an account URL.

## Chords and rights

The publisher's [chord reference](https://www.pisni.org.ua/articles/11.html)
explicitly equates B with Hb/A-sharp and labels H as B-natural. Conversion is
therefore scoped to this source: B becomes Bb, H becomes B, including slash
bass. No shared chord parser or other provider's notation changes. Original
labels and layout remain retained with the source evidence URL.

Chord rows are interpreted from the preformatted layout and anchored to the
following lyric line's columns. Cyrillic words are never Latin chord aliases.
Ambiguous unindented single-letter notes stay literal with explicit ambiguity
facts rather than consuming lyric lines. Unsupported tab layout fails instead
of silently shifting chords. This is document notation, not recording, key,
timing or audio-alignment proof.

The [publisher rules](https://www.pisni.org.ua/articles/34.html) require source
and author information for contributions. They do not establish a blanket
reuse license. Per-work rights remain unknown, and no license is invented from
public accessibility or attribution.

## Evidence

Twenty-six focused provider tests pass, covering legacy form/Unicode handling,
variant IDs, role/album boundaries, canonical identity, source spoofing,
cancellation, cache behavior, source-note privacy, ambiguous lyric letters and
ChordPro retention. A separate disposable AppController/SQLite test saves,
reopens and exports both actual captured source documents exactly: 27 tests in
the combined qualification. Scoped analysis is clean. No user library or
device was used.

Two actual native search/resolve canaries passed on 2026-10-27 at
23:32:18–23:32:24 UTC: document3424, **Червона рута**, and document8878,
**Ой у лузі**. Four HTTP200 responses, no network failure or retry, with a
1.1-second host interval. They retain respectively seven/three listed
performers, two/three formal role credits, five source-information fields,
original HTML bytes, chords and attribution. Exact source facts survive
ChordPro round trips; recording IDs remain empty.

Live-tested provider SHA-256:
`b0685815e90b8086a9279920d4ca845e9a4e707f14fc86bdb5f9567ee67e7e16`.
The final module differs only by adding braces around a single conditional
return for lint compliance; the exact live-tested snapshot and diff are kept
privately. Final provider SHA-256:
`7a350a2a66f8933fa4b1a4a9db86a9eaf8178cab7b026606a17470851aff048e`.

These selected new-capability checks did not rerun the production datasource
suite or change production health reports. Source HTML/lyrics remain private;
public evidence records hashes, field counts, runtime and request provenance.
This qualification does not establish corpus-wide coverage, an app installation,
managed-cloud reachability or a public release.
