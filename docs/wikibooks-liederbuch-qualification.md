# Wikibooks Liederbuch source proposal

This unregistered proposal is based on public main
`c77b221f1575236923b22dcea0f6672887bf11af`. Its only product changes are the new
adapter and synthetic tests. No registry, catalog, client, cache channel,
existing provider, version or release artifact is changed. The provider's
definition is off by default. Public-main integration and a compatible app
remain separate work.

## Publisher interface and scope

The German Wikibooks [Liederbuch project](https://de.wikibooks.org/wiki/Liederbuch/_Inhalt)
collects song sheets with notation or chords. Its repertoire includes folk,
regional and other songs; it is not a dedicated religious catalog. The
publisher's category page displays 201 members, which is not a measured count
of usable lyric sheets or incremental coverage.

The book's [markup guidance](https://de.wikibooks.org/wiki/Liederbuch/_Hilfe)
documents inline chord templates, source credits and German versus international
chord spelling. The adapter uses the documented MediaWiki
[search API](https://www.mediawiki.org/wiki/API:Search) and
[page parse API](https://www.mediawiki.org/wiki/API:Parsing_wikitext), with an
identifying app User-Agent, `formatversion=2` and `maxlag=5`. It makes no account,
cookie, browser, script, score, audio, image or video request. Search is limited
to ten main-namespace rows in the `Liederbuch/` title family. Resolve additionally
requires the book's song category, a matching numeric page ID/title and a
positive revision ID. Non-song book pages may appear in search and are rejected
at resolution rather than imported as lyrics.

## Bounded extraction and preservation

Only poem blocks become lyrics. All top-level blocks and their source headings
are retained in publisher order; nested poem containers are not duplicated.
HTML paragraph and line breaks retain verse boundaries. Superscript chord
template spans produce chord anchors; ordinary brackets, braces, hashes and
directive-shaped text remain literal. The template's tiny white layout brackets
are omitted. Semantic navigation and footnote citation markers are not lyrics;
footnote text stays in source data. Score-image alternative text is never used
as lyrics or inferred key/tempo. Images or unsupported active markup inside a
poem fail explicitly rather than silently dropping possibly meaningful content.

The source's song-language category supplies the documented notation context:
German H/B and international B/B-flat remain distinct. Ambiguous B/H with no
single language context is unsupported rather than guessed. Unrecognized
annotations are retained literally and recorded separately. This does not
establish musical correctness or complete corpus grammar coverage.

Page/revision identity, categories, source text/melody provenance, arranger
credits, alternative titles, credit links, heading/block structure, footnotes
and exact original API bytes/hash remain attached to the source. Provenance
phrases are not promoted into performer, recording, album or playback facts.
The source identifies an arrangement page, not a studio recording.

Responses are bounded to 2 MiB and JSON/HTML depth is checked. Successful API
bytes are cached for 15 minutes within 16 entries / 4 MiB; errors, cancellation
and rejected content do not replace a valid cached response. Cold callers do
not share a cancellation-sensitive request. Candidate URLs and supplied metadata
cannot redirect the fixed-host resolver or become resolved source facts.

## Rights and attribution

The captured siteinfo response identifies page contributions as CC BY-SA 4.0.
The document's underlying lyric/music license remains `unknown`; contribution
terms and their link are separately scoped in field-specific rights metadata.
Attribution includes the page, revision permalink, contributor credit, license
link and the HTML-to-ChordPro modification. History links and original bytes are
retained. This does not assert blanket clearance of every underlying song or
arrangement. Compatible attribution/share-alike presentation and portable export
must remain intact through integration.

## Evidence and remaining gates

On 2026-10-28 at 05:39 UTC, five identified local HTTP requests returned 200:
siteinfo plus independent search and parse responses for page 118857,
revision 1036453, and page 115615, revision 1083680. There were no retries or
credentials. Those were API contract/shape probes, not app extraction proof.

The current adapter then passed a pure-Dart offline replay of the retained
responses through ordinary production matching, combined-document generation
and ChordPro export/import. Two independent reference extractions from the
captured HTML matched every lyric line, chord sequence and all 67 chord-anchor
positions. Page revisions,
credits, exact source bytes/hash, attribution and scoped rights survived the
round trip. The initial replay used four fixture requests; the separate anchor
qualification used four more. Both made zero network requests. Actual
source bodies and the independent lyric reference stay ignored and private;
committed tests contain only invented text.

Static review found and corrected a package-DOM API mistake before execution
and tightened notation-specific validation. The subsequent static review found
no remaining blocker. Focused Flutter tests and analysis have not run locally;
the coordinator granted only the bounded pure-Dart retained-response replay.
No native device, SQLite reopening,
fresh live adapter probe, managed-cloud reachability, registry/catalog rollout
or release is qualified by this replay. The captured search request used a
five-row limit; the bounded adapter requests ten, so fresh exact-request canaries
remain necessary when that phase is authorized. Coordinator review approved
[draft PR 208](https://github.com/freevia-org/Singbook/pull/208) for hosted
validation. It remains unregistered and inactive pending those checks and
further qualification. It must not change or delay the separate release-43
work or the frozen OpenScore proposals.

## Follow-up qualification on 29 October 2026

The adapter was integrated unchanged and remains unregistered. Current public
main `1a4573eefc7f0f0e28c8ab7ab77cd4479c1d2a05` has module SHA-256
`d1e7c9361d587c4bd5fb98ff52467be732c651661c4d21827d14aad60f14963a`,
matching the final live-qualified PR208 adapter. Its two exact-request canaries
passed on 28 October at 07:05 UTC: four HTTP 200 responses, no retries, both
independent lyric references and all 67 chord positions matched. The final
PR208 checks also passed. These later results supersede the earlier preparation
limitations above; they do not qualify a new registry or app release.

A separate host Flutter qualification on 29 October replayed those same four
captured responses through the production adapter, ordinary AppController
search/selection/save, isolated SQLite close/reopen and ChordPro export/import.
Both complete saved documents, source metadata, original API bytes/hashes,
revision/history attribution and separately scoped contribution/underlying-work
rights survived exactly. The default-off preference was explicitly enabled and
persisted. The independent lyric lines and chord anchors still matched. This
was zero-network retained-response evidence, not a fresh publisher or device
run. Raw documents and the disposable QA library stay ignored and private.

`test/application/wikibooks_liederbuch_flow_test.dart` provides a synthetic CI
regression for this controller/persistence contract, including German H/B
notation, original payloads, portable rights/history preservation, and disabling
the provider without deleting saved songs or losing the opt-out on restart.
All text in that test is invented.

Remaining gates are compatible registry/catalog/cache rollout, native-device
app qualification, managed-cloud reachability and integration/release review.
The contribution license does not become blanket clearance of underlying works;
their unknown status remains explicit in portable source evidence. No provider,
catalog default, release artifact or production report is changed by this
persistence follow-up.
