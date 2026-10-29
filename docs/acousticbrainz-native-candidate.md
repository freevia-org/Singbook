# AcousticBrainz metadata candidate

PR217 prepared and qualified the standalone adapter; PR223 connects it to a
compatible channel10 registry, bounded recording-context discovery, and the
existing source-details panel. PR212 records discovery. PR216 separately
prepares publisher-window handling in the shared transport. Frozen release45
and all nine older catalogs are untouched by this candidate.

The candidate is not a published or installed app release. The app/controller
and portable-storage checks below use authored HTTP fixtures, while the
separate retained compiled-adapter canaries use real publisher responses.
Neither establishes managed-cloud reachability or native-device qualification.

## Access and scope

The [publisher](https://acousticbrainz.org/) ended collection in 2022 and keeps
its archive/API available. Its CC0 statement covers the analysis corpus. This
module neither retrieves nor claims rights to recordings, lyrics or artwork.
The displayed corpus statistics are dated 2022; they are not a current usable
coverage count for this app.

The [documented API](https://acousticbrainz.readthedocs.io/api.html) accepts
recording MBIDs. There is no title search in this module. A normal name query
returns no candidates without HTTP. A valid explicit recording MBID permits
one bounded count request and one filtered low-level bulk request, sampling at
most offsets 0 and 1. These offsets are submission positions, not quality or
authority. Counts and retrieved offsets remain explicit; a count of 148 with
two samples is never labelled complete or consensus. No corpus enumeration,
audio upload, account, token, cookie, media or arbitrary URL fetch is used.

The fixed HTTPS host and 512 KiB response bound apply to both reads. Requests
are spaced at least 1.1 seconds by default within this adapter; queued pacing
is bounded to 15 seconds and cancellation is polled during waits. Ordinary
shared-transport retries remain separate HTTP requests. This spacing alone
does not implement dynamic per-IP limits: integration requires the reviewed
publisher-window handling from PR216 or an equivalent validated transport
contract. Other clients can consume the same IP budget. A 429 is not evidence
that daily scheduling ran too often.

## Identity and estimates

The selected MBID must agree with every sampled submission's MBID tag. Parsed
title and artist come from the response, rather than copying selected text
over contradictory tags. Missing/ambiguous identity, contradictory samples,
or supplied title, artist, album or duration disagreement fails explicitly.
Multiple submitted artist tags are not reduced to the first artist. Explicit
edition compatibility uses the existing domain check without changing it.
These checks validate submitted metadata consistency, not the original audio.

All returned tags, extractor versions, source file lengths and both sampled
key/tempo estimates remain under `metadata.acousticbrainz`. The module does
not populate canonical key/BPM, timing tracks, chord charts, release artwork
or a canonical album/duration from uploaded file tags. Estimate and audio
alignment status remain unverified. Response bytes and hashes are retained
separately for count and analysis JSON; the input selected candidate's other
identifiers and metadata are not echoed as publisher facts. The cache is
bounded to 32 recordings and 15 minutes, and context is checked again on hits.

## Existing evidence and validation limits

Three earlier bounded local API reads at 2026-10-28 12:49–12:50 UTC returned
three HTTP200 responses without retries. Private retained files and redacted
reports are in `artifacts/datasource-expansion/acousticbrainz-20261028` in the
datasource worktree. Those reads predate this module and are feasibility
evidence, not execution or live qualification of the new Dart code.

They include Mysterons / Portishead, recording
`b5d7d380-f43a-4c1f-a5de-694150b093ac`, count 148, with differing BPM values
at offsets 0 and 1; and Colors and the Kids / Cat Power, recording
`099b148e-fe99-4b79-be6e-5078e4bb7415`, offset 0. Wonderwall's requested MBID
was omitted, as the API documents for unavailable records. This module has
not established its total count for the Cat Power example. The exact retained
responses use different bulk combinations; an authored combined fixture is
not presented as an unchanged live HTTP capture.

Authored focused tests cover request bounds, identity and edition contradictions,
multiple submissions, omission/schema failures, estimate isolation, raw-byte
and ChordPro retention, cancellation and cache behavior. They are authored
fixtures, not independent musical accuracy assessments. Initial preparation
used no local SDK/test/analysis/build/device or new live API call, under the
coordinator's preparation-only instruction. Subsequent coordinator-dispatched
hosted validation at `7ac5291` passed analysis, UX, Wikisource, macOS compilation,
Windows build and journey checks. Its Linux test suite exposed an incorrectly
inferred integer-only map in the deliberately invalid-count fixture; the test
failed before calling the provider. Commit `d91d3ff` replaces that row with an
explicit dynamic-valued map. The adapter's executable code did not change.

Exact standalone head `f8f31a9b0fbdff201337e3f342ac1ef3063250b7` subsequently
passed hosted CI (Linux and both Windows suites), macOS, UX and Wikisource
validation. Two actual compiled-adapter canaries passed on 2026-10-28 using four
HTTP200 requests, zero transport retries: Mysterons / Portishead (148 submissions)
and Colors and the Kids / Cat Power (44 submissions). Both retained offsets0/1,
raw response bytes/hashes, source tags and extractor estimates. The sanitized
receipt is on `codex/datasource-health` at
`reports/source-maintenance/local/qualifications/2026-10-28T162355Z-acousticbrainz-compiled-live/report.json`.
This branch adds the compiled receiver capability without changing extraction
semantics; it does not repeat unchanged live canaries.

## Ordinary app integration

Discovery defers native receivers missing a recording identifier, completes
existing source work and the established bounded MusicBrainz context retry,
then permits one receiver lookup. An accepted donor must already be an
unambiguous canonical MusicBrainz recording, independently associated with the
original selection through resolved recording evidence. No extra MusicBrainz
search is issued; a same-song-only donor, conflicting identifiers/editions or
cumulative duration drift cannot supply context. Existing IDs use the ordinary
initial lookup, without a duplicate late pass.

The receiver must return the exact consumed MBID. Dependency cancellation,
opt-out and synchronous progress callbacks are checked before/after operations
and completion; withdrawn proof rejects dependent results. Original selection
and full source hashes remain bound during discovery. UI revalidation checks
current eligible witnesses, normalizing only controller-owned merge/history
bookkeeping and duplicate facts already present in the still-hashed candidate.
It cannot substitute archived payloads as active recording proof.

The existing version-details panel shows both sample estimates, explicit
unverified status and shown/total submission coverage. Its bounded projection
excludes uploaded filenames and arbitrary tags/URLs. It does not copy estimates
into canonical key, tempo, duration or timing. Four labels are localized in all
34 supported locales.

The authored ordinary-controller test uses the configured native adapter,
checks two bounded mock HTTP responses, safe UI mapping and recording proof,
then saves the combined document, reopens SQLite and round-trips ChordPro.
Every source fact, raw response and attribution/provenance envelope survives.
Fresh widget screenshots cover phone, large text, Arabic RTL/dark, Ukrainian
dark and landscape layouts. These are host widget captures, not device proof.

Remaining publication gates: exact final-head hosted checks, native-device app
qualification, managed-cloud reachability and integration review/public-main
publication. Older channels and saved opt-outs remain protected. Candidate
catalog activation is not evidence those external gates have passed.
