# OpenScore Lieder source-only proposal

The adapter in `lib/providers/extra/openscore_lieder.dart` searches the publisher's
generated public metadata index and reads an individual publisher-provided `.txt`
lyric file for an explicitly selected score ID. It is **not registered, enabled,
published in a source catalog, or qualified in a released app**. It must not delay
the separate release-43 rollout. A later compatible catalog/runtime proposal and
native/cloud qualification are required.

## Publisher interface and content

[OpenScore's README](https://github.com/OpenScore/Lieder/blob/38c5db510224d9facdc4b08d741fc788cfb58ea8/README.md)
documents the score-directory layout, stable MuseScore score IDs, matching plain
text lyric files and structured metadata. These lyric files are automatically
extracted from score parts. The adapter uses raw GitHub text only; it never
downloads MuseScore/IMSLP scores, audio, images or video, runs catalog scripts, or
uses an account.

The [generated index](https://github.com/OpenScore/Lieder/blob/38c5db510224d9facdc4b08d741fc788cfb58ea8/data/index.html)
had 1,462 table rows in the measured response. The separately maintained
[summary](https://github.com/OpenScore/Lieder/blob/38c5db510224d9facdc4b08d741fc788cfb58ea8/data/corpus.yaml)
reports 1,454 scores by 143 composers. These are distinct publisher observations,
not a synchronized census or a count of available lyric files. Regional overlap
and incremental coverage remain unmeasured.

The publisher [dedicates the corpus under CC0](https://github.com/OpenScore/Lieder/blob/38c5db510224d9facdc4b08d741fc788cfb58ea8/LICENSE.txt)
and requests OpenScore attribution and a repository link. CC0 does not clear
third-party rights the affirmer does not own. The adapter retains that dedication,
source attribution and an explicit underlying-rights-unverified status rather
than declaring every embedded poem or translation public domain everywhere.

## Identity, extraction and request bounds

- A numeric score ID identifies a particular source score/composition. Composer
  remains a composer credit; lyricist remains a lyricist. No performer, album,
  recording ID, timing, key, tempo, chord progression or harmonic analysis is
  inferred. A collection/cycle is retained as `sourceWorkSet`, not an album.
- All five textual catalog columns and bounded score/external references are
  retained as source metadata. References are links only and are not followed.
- Search parses at most 2 MiB / 5,000 catalog rows and returns at most 30 matches.
  An instance caches a successful index for 24 hours. Failed or cancelled refreshes
  do not replace the cache. Concurrent initial searches share the fetch.
- Resolve revalidates ID, title and composer against the catalog. Caller URLs,
  paths and recording metadata cannot supply source facts or network targets.
  Conflicting duplicate IDs are omitted. Only the fixed publisher repository and
  expected directory/file layout produce a bounded 256-KiB plaintext request.
- Plaintext syntax is escaped literally, including bracketed lines, hashes and
  directive-shaped text. Original UTF-8 bytes and their hash remain separate from
  the rendered ChordPro body. No verse boundaries or repeat structure are invented.

## Measured qualification and limitations

Local identified HTTP on 2026-10-28 fetched the index once (HTTP 200), followed by
one attempted Arne score lyric file (ID 8835588, HTTP 404). The publisher directory
confirms that score has notation files but no `.txt`; no fallback download or
retry was attempted. A missing lyric file remains `unavailable` and does not
retire the source or trigger notation parsing.

Two subsequent directory-confirmed plaintext canaries passed ordinary adapter
search/matching and live per-ID retrieval:

| Score ID | Work / composer | Language | HTTP body bytes |
| --- | --- | --- | ---: |
| 6573780 | Der Erlkönig / Emilie Mayer | German | 1,383 |
| 6217099 | 3 Clair de lune / Marie Jaëll | French | 1,004 |

Their searches reused the fresh real index snapshot. Each lyric request returned
HTTP 200, without retry. Both source files contain automatically extracted text
on one line. These checks establish usable source text and metadata for those two
scores, not independent transcription accuracy, stanza fidelity, or complete
corpus availability. Request accounting is four local source HTTP attempts total:
one index, one missing file, two successful files. Documentation and repository
directory reads are separate research requests. No full production suite was
repeated and production latest reports were not replaced.

Synthetic provider tests cover identity, canonical paths, duplicate IDs, cache
reuse, unsafe content, cancellation and preservation of literal lyric syntax.
Retained-response replay additionally checks combined-body and portable ChordPro
source-metadata/raw-payload/rights retention. That does not substitute for native
library/SQLite, Android reader, compiled registry/catalog or managed-cloud tests.

Run the focused test when the shared Flutter SDK is available:

```powershell
flutter test --no-pub test/providers/extra/openscore_lieder_test.dart
dart analyze lib/providers/extra/openscore_lieder.dart test/providers/extra/openscore_lieder_test.dart
```

Before activation: review this source against the current compatible runtime;
add a separately versioned catalog and source registry only through integration;
run structural/default/opt-out compatibility checks, real native import/save/
reopen and portable-source preservation, and selected-source cloud checks.
Keep all older served channels, saved libraries and explicit opt-outs intact.
