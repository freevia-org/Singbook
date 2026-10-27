# Start Jamming source qualification

Start Jamming supplies bluegrass lyrics, independent chord progressions and
optional metadata through its [documented public API](https://www.startjamming.com/api).
Read endpoints require no key. Every song request includes `for=agent`, uses
the returned canonical ID and URLs, and honors ETags. This integration uses
interactive search and full-song reads, without downloading a bulk catalog,
audio, PDFs or videos. Corpus size and incremental coverage remain unmeasured.

The API does not align lyrics with chord measures. The adapter therefore keeps
lyric variants and a separate chord progression, retaining ordered sections,
repeat counts, expanded beats and rests. It preserves the complete returned
JSON and actual HTTP-client body bytes; these are not claimed to be compressed
wire bytes. Source timing is not invented. Optional unknown artist/recording
identity remains unknown. A selected canonical arrangement with an empty artist
can save only its own verified chart; title alone never authorizes a foreign
provider or recording match.

Agent responses intentionally omit licensing. The integration preserves an
unknown per-work rights status and canonical Start Jamming attribution; public
API access is not represented as a lyric reuse license. `lyrics_alternates`
labels array-valued lyrics by index according to the publisher guide. Array
variants are covered by synthetic fixtures; the live canaries below returned
single or absent lyrics.

## Local evidence, 2026-10-27

Two canonical canaries passed normal native adapter search, AppController
selection, save, full source ChordPro export/import and actual SQLite close and
reopen at 14:41:53Z. Exactly four local HTTP requests returned 200, with zero
retries, network failures, Retry-After responses, cookies or credentials. The
transport used one-second minimum host pacing.

| Canonical source | Observed content | HTTP-client detail body SHA-256 |
| --- | --- | --- |
| [Clinch Mountain Backstep](https://www.startjamming.com/song/clinch-mountain-backstep) | No lyrics; 8 measures, 33 expanded beats, section repeats, key and meter. | `292cdd4b29dc02325d5691fb60737018daa39ed110c55f41714dd662612cffc9` |
| [Blue Moon of Kentucky](https://www.startjamming.com/song/blue-moon-of-kentucky) | Lyrics plus 33 independent measures, 99 expanded beats, key and meter. | `854a5065dec11f34b69f7079260aa2e662df739945f89803397302553e940330` |

Both preserve canonical identity, lyric order, source facts, attribution,
unknown rights, and demo links. No artist credit, recording ID or timing was
present or invented. Replay of the separately captured original responses also
passed. A real replay exposed a chorus closing directive appended to its lyric
line; regression tests now verify that section directives occupy their own
lines and inline tags do not split lyric lines.

The opt-in `tool/startjamming_import_maintenance_test.dart` reproduces these four
requests and emits a sanitized report under `artifacts/`. Set
`SINGBOOK_LIVE_STARTJAMMING_CHECK=1` only for an intentional qualification run.
Ordinary CI skips network access. The source CLI can use regular declarative
probes once a compatible catalog channel includes the source.

The maintenance harness also distinguishes a nonempty chord chart from lyric
text: only actual plain lyric lines verify the `lyrics` capability. An
instrumental canary can verify chords and metadata while a vocal canary
separately establishes lyric extraction.

## Release gates

The native adapter registration alone does not change any existing catalog
stream. A compatible catalog, daily worker selection, public-main integration,
app release, Android visual/import testing and managed cloud reachability are
separate gates. These local checks establish neither current production
activation nor Android screen behavior nor cloud health. Older catalog/cache
channels must keep their existing source rosters and preferences.
