# Optional exact-release artwork through MusicBrainz

Channel-5 revision 17 adds optional Cover Art Archive front previews through
the existing MusicBrainz provider (source revision 3). There are still 26
entries. Other 25 entries and channels 1–4 are unchanged. This catalog needs
the matching compiled implementation before production distribution.

An explicit `musicbrainzReleaseId` is verified directly. Otherwise the exact
recording's untruncated linked releases must contain one distinct release
matching the selected album, or one release overall without album context.
A 25-entry list cannot establish uniqueness: the
[MusicBrainz API](https://musicbrainz.org/doc/MusicBrainz_API) caps linked
entities at 25. No first-release or release-group representative is selected.

The release lookup must confirm its UUID, album when known, and exact
recording UUID in a valid track list. Missing, contradictory or darkened art
is omitted. Success uses the exact release title consistently and retains
normalized release JSON, without claiming original response-byte retention.

Only the documented fixed HTTPS CAA `release/{releaseId}/front-500` URL is
emitted. The existing renderer handles image delivery. The provider does not
fetch the redirected JSON index, construct CDN URLs or broaden shared redirect
restrictions. See the [CAA API](https://musicbrainz.org/doc/Cover_Art_Archive/API)
and publisher's [redirect implementation](https://github.com/metabrainz/artwork-redirect).

Optional release work has a four-second total child-cancellation budget,
including pacing, queue waits and retries. Failure keeps recording metadata;
caller cancellation still propagates. Successful release details use a
32-entry, 15-minute cache; transient errors are not cached. Numeric
`Retry-After` remains a host cooldown after cancellation or exhausted retries,
and normal pacing cannot shorten it. Publisher quotas still apply.

`artworkAssets` retains URL, exact recording/release binding, credit and unknown
rights. The [CAA policy](https://musicbrainz.org/doc/Cover_Art_Archive) grants
no blanket image license; MusicBrainz metadata CC0 does not apply to images.
SQLite/ChordPro preserve these facts and URLs. Image pixels are cached in
memory, not persistent offline storage; an offline reader may show a placeholder.

Maintenance reports extracted locations/provenance with
`artworkImageBytesValidated: false`; image decoding is a separate check.
Optional art timeout/block is not a schema regression. Unrelated missing
recording metadata remains `changed_schema`, with the art failure recorded too.

## Local evidence, 2026-10-27

Primary publisher examples supplied these independently verified releases:

| Release | Recording | Artist | Album |
| --- | --- | --- | --- |
| `5b07fe49-39a9-47a6-97b3-e5005992fb2a` | `b5558485-68a8-4c6c-8283-60e6ae940e06` | (S_S) | Final Fantasy VII Chips |
| `76df3287-6cda-33eb-8e9a-044b5e15ffdd` | `b5d7d380-f43a-4c1f-a5de-694150b093ac` | Portishead | Dummy |

Native matching passed at 12:18:37Z–12:18:42Z: four HTTP 200 responses, no
retries/network failures. Both canonical image routes returned decodable JPEGs
at 12:21:39Z–12:21:45Z: 500×500 and 494×500 pixels. Images and API documents
remain private. The QA diagnostic first stopped at unreviewed Canadian Archive
datanodes. After reviewing the trusted archive.org redirects and exact item
paths, its bounded re-probe passed. No denial was bypassed or app redirect
policy broadened.

Full-catalog offline validation passes. The registered CLI at 12:44:07Z
passes the existing search/recording canary and both artwork canaries, covering
catalog/metadata/artwork extraction. All 721 combined provider/controller/UI
cases pass. Controller/SQLite/ChordPro tests preserve complete source facts,
rights and hashes; a conflicting recording cannot donate artwork.

Hosted checks, Android update/import/display/persistence, public integration,
served-catalog verification, compatible distribution and managed-cloud probes
need separate dated evidence. Local success does not prove cloud reachability.
