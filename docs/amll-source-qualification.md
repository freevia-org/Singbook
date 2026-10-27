# AMLL native adapter qualification

The native adapter is prepared for a compatible future app/catalog rollout.
It is not registered in the default provider factory or added to either
published catalog. Older clients reject unknown native IDs even when disabled;
the integration coordinator must select a compatible new distribution channel
and app build before activation. Frozen release 39 is unchanged.

## API and identity

The publisher documents anonymous native search and exact document retrieval:

- [API contract](https://amll.dev/reference/http-api/native)
- [Limits and immutable-ID caching](https://amll.dev/reference/http-api/overview)
- [TTML format](https://amll.dev/en/guides/lyric/ttml)
- [Database and ecosystem](https://amll.dev/guides/overview/eco)

Search uses `/v1/lyrics/search`, with ordinary free-text queries or separate
selected-song title/artist/album filters. Collaboration names are not reduced to
an assumed lead artist. Current search rows omit `format` and `lyrics`; detail
from `/v1/lyrics/get?id=...` must declare `format: ttml` and contain flat `lyrics`.
Malformed containers, contradictory formats, and changed identities fail.

Document IDs are canonical positive decimal integers within JavaScript's 53-bit
safe range. All title/artist/album aliases, platform IDs and contributor
IDs/usernames remain attached to the source. Contributor names are not
songwriter credits. Full artist sets are checked without depending on their
array order when resolving a selected document. Cross-provider matching still
uses the app's existing conservative identity rules; every collaboration credit
syntax and version has not been qualified.

The adapter retains the original JSON response and exact TTML, including
translations and romanization. Each array is bounded at 30 nonempty strings;
larger arrays are rejected rather than truncated. Requests accept up to 1 MiB
of JSON and 512 KiB of TTML. Up to 32 validated immutable detail responses are
cached per provider instance. Cached data is rechecked against every selection;
failed, cancelled and invalid responses are not cached. Normal transport limits,
TLS, cancellation and access-denial handling remain in force. The adapter queues
operations at least 150 ms apart, below the documented 50 requests/second limit.

## Timing and provenance

The explicit `amll-ttml` parser profile supports absolute decimal seconds and
short media clocks. The root must use the TTML namespace. Older documents may
omit the timing marker; a present marker must use the publisher's exact Apple
namespace and Word/Line value. Generic W3C relative timing is unchanged.

Translation and romanization spans remain in the raw document, outside the sung
text and normalized cues. Background vocals become separate lines with their
own intervals and voices. This follows the publisher's
[background-vocal conversion](https://github.com/amll-dev/applemusic-like-lyrics/blob/main/packages/ttml/src/utils/amll-converter.ts):
their clocks can outlast the foreground paragraph. Body bounds and ordinary
child bounds remain checked; no source clock is clamped or invented. Ruby
annotations and sequential containers remain unsupported until separately
qualified, with the raw document retained.

A lyric document identifies an arrangement, not a verified audio recording.
Platform identifiers are retained as source facts without choosing an ambiguous
recording ID. Timing uses the existing source-only guard and is not automatically
promoted to usable recording timing. The publisher's CC0 database claim does not
independently establish rights in the underlying lyrics. Source and contributor
attribution are retained with unknown underlying-work permissions.

## Local evidence, 27 October 2026

The final production-provider/configured-maintenance run at
2026-10-27T06:59:51Z passed two independent canonical and two exact-ID search
canaries: ME! / Brendon Urie & Taylor Swift (269710089745311, Lover), and
Shape of You / Ed Sheeran (638303942317135, Pop). Four requests returned HTTP 200,
with no retries or network failures. The same documents retain respectively
84/99 primary-plus-background line cues and 567/727 word cues. Exact first word
intervals are 115000–237000 and 9929000–10076000 microseconds. These checks verify
response identity consistency, extraction, field presence and preservation;
they do not independently verify transcription or audio alignment.

The earlier live attempt exposed the omitted search `format` field; its two
canonical probes passed and two search probes failed. That evidence is retained
separately from the repaired final run. Two real snapshots also passed isolated
AppController/native SQLite reopening and ChordPro round trips: source IDs,
contributor arrays, original JSON, raw TTML, cue facts and document timing remain
intact. The existing codec shares derived timing status/binding by track ID, so
full source JSON byte equality after export is not claimed.

Regional coverage, catalog size, overlap, cloud reachability, default app roster
activation, and device UI testing remain unverified for this adapter.
