# AcousticBrainz metadata candidate

This draft contains an unregistered module and authored contract tests. It is
based on public main `bd4a651bc7b0d0ebc6629c12c81707f4ba0eaf4b` and changes no
factory, catalog, transport, routing, model, release artifact or app setting.
It is not a working source in the current app. PR212 records discovery;
PR216 separately prepares publisher-window handling in the shared transport.

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

Focused tests cover request bounds, identity and edition contradictions,
multiple submissions, omission/schema failures, estimate isolation, raw-byte
and ChordPro retention, cancellation and cache behavior. They are authored
fixtures, not independent musical accuracy assessments. **No Dart/Flutter SDK,
test, analysis, build, device or new live API call has been run for this draft**
under the coordinator's explicit preparation-only resource instruction.
Compilation and test success remain unproven. A static review cannot replace
those checks.

## Required integration work

Ordinary app selections often lack a recording MBID. The discovery service
currently starts providers against its original selection and has specialized
MusicBrainz context handling. This module does not change that service. A
validated late recording-context route is required before normal app use;
direct-ID lookup alone does not complete integration. The route must preserve
source enablement, cancellation, ambiguity/edition checks and provenance,
without duplicate speculative MusicBrainz searches or invented identifiers.

Before registration or activation: run and review the focused SDK tests and
analysis, qualify the exact compiled adapter against two real independent
recordings using a bounded documented request budget, test ordinary app
discovery/save/offline reopening and complete source-fact retention, establish
managed-cloud reachability, and introduce the compatible registry/catalog
channel atomically. Preserve older served channels and saved opt-outs. None
of these gates is satisfied merely by merging an unregistered module.
