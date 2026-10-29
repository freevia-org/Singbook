# Implemented source capabilities

The prepared channel-5 runtime registers 26 sources, adding TouhouDB and UtaiteDB to the 24-entry AMLL/VocaDB runtime. Older channels keep their own compatible lists: channel 2 has 22 entries, including lrc.red, Roswell Music Jam and kara.moe, and released channel-1 clients keep 19. The new channel still needs integration and a compatible app release. The source list, lifecycle, capabilities and compatible JSON/HTML extraction rules can evolve through the online catalog. See [source maintenance](source-maintenance.md) for refresh, validation and daily repair/discovery. Registered entries include retired and import-only sources; availability and fields vary by song.

| Source | Access in this app | Lyrics | Chords | Timing retained | Additional source information |
| --- | --- | --- | --- | --- | --- |
| Genius | Token-authenticated catalog/detail API; public song-page extraction | Plain text | No | None | Album, artwork, release date/year, language, artist/writer/producer and other credits, media links |
| Songsterr | Structured data from public search and chord pages | Chart's own lyrics | Positioned on the chart's own words | None | Explicit key, capo, tuning, tempo, time signature, album and song-level videos; tab instrument settings are not applied to the chord sheet |
| Ultimate Guitar | Public user **Chords** sheets only; excludes Official/Pro/private results | Chart's own lyrics | Positioned on the chart's own words | None | Explicit key, capo, tuning, difficulty, genre, recording descriptors, artwork, transcriber, videos; explicit contributor preamble tempo/time signature |
| LRCLIB | Public JSON API | Plain text and LRC | No | Original LRC, line cues, enhanced-LRC word cues if supplied | Album, duration, instrumental flag |
| YouTube Music | Unofficial public web-client JSON endpoints; anonymous requests | Actual recording's lyrics shelf; video descriptions/URLs do not count | No | None from the implemented shelf | Album, duration, artwork, playback link, supplier attribution |
| Lyrics.ovh | Public suggestions and artist/title lyric API | Plain text | No | None | Deezer suggestions supply album, duration, recording label, artwork, playback/preview links. Artist/title-only lyric retrieval does not establish the recording. |
| SyncLRC | Public search, separate track/artist lookup and documented canonical-ID retrieval; existing carried selections retain their exact variant | Plain, synced and karaoke variants | No | Both original synced/karaoke documents, line and enhanced word cues | Returned album, duration, instrumental flag; identity and edition checks remain mandatory |
| Better Lyrics | Cached TTML API; LRCLIB recording catalog | TTML text | No | Original TTML, line/word cues, boundaries, source time expressions and unsupported payloads | Album/duration are required for retrieval. Cache misses, access denial and service outages do not produce fabricated lyrics. |
| Unison | Documented public search/by-ID API through catalog-defined JSON rules | Plain, LRC or TTML according to the response format | No | Original LRC/TTML and parsed cues; two independent live TTML songs verified both explicit line cues and positioned word cues | Fixed provider attribution and source URL; composition identity is retained without assuming a particular recording. |
| lrc.red | Public identified search/detail API; active in compatible channel-2 app builds | TTML text | No | Original TTML and explicit line/word timing profile | Exact ISRC, album, duration, songwriter credits, release date, language and linked album artwork; unknown redistribution rights |
| Roswell Music Jam | Public publisher-linked ChordPro ZIP; searchable individual charts, in-memory 24-hour cache; active in compatible channel-2 app builds | Chart's own lyrics | Chart's own positioned chords | None supplied | Key, capo, tempo, composer/lyricist credits, source collections and original ChordPro; arrangement identity and unknown redistribution rights |
| kara.moe | Public documented karaoke search/detail JSON API; active in compatible channel-2 app builds | The source video's lyric text, including cuts/covers where identified | No | Parsed line cues and original JSON/subtitle tags; video timing stays unverified for song recordings | Multilingual titles, actual singer/songwriter and karaoke-author credits, language and source collections; video year/duration remain separate from song release facts. Database and synchronization licenses do not establish lyric-text rights. |
| AMLL Lyrics Database | Anonymous native search/detail API; active in compatible channel-3 code/catalog | Primary and background lyric lines; translations and romanization retained in original TTML | No | Explicit media clocks, line/word cues and original JSON/TTML; source-only timing is not verified for a selected recording | All bounded title/artist/album/platform/contributor arrays, exact immutable document ID and source attribution. Document IDs identify lyric arrangements; database CC0 claims do not clear underlying lyric rights. [Qualification and rollout scope](amll-source-qualification.md) |
| VocaDB | Anonymous native API; active in compatible channel-4 candidate code/catalog | Unique original lyric selected; all translations/romanizations and source credits retained separately | No | No timing or confirmed recording identity | Multilingual names, full artist roles/album records, languages and BPM ranges retained. Explicit composer/lyricist roles and fixed BPM normalize without guessing. Metadata CC BY 4.0 excludes third-party lyrics/artwork. [Qualification and rollout scope](vocadb-source-qualification.md) |
| TouhouDB | Anonymous native API; prepared compatible channel-5 code/catalog | Unique original lyric; all variants/source credits retained | No | No timing or confirmed recording identity | Touhou arrangements, aliases, full roles/albums, BPM/cultures and original-version relationships. No parent lyric substitution for a cover/remaster. [Qualification and rollout scope](regional-source-qualification.md) |
| UtaiteDB | Anonymous native API; prepared compatible channel-5 code/catalog | Unique original lyric; all variants/source credits retained | No | No timing or confirmed recording identity | Utaite originals/covers, aliases, full roles/albums and version facts. One bounded exact-name contextual fallback can find an original crowded out by highly rated covers. [Qualification and rollout scope](regional-source-qualification.md) |
| WorshipCommons | Approved public repository catalog, filtered to PD / CC-BY / CC-BY-SA | ChordPro | When the document supplies them | Original demonstration timing JSON with word starts/durations; never assumed to be timing for a selected cover | Writer, composition year, language, key, tempo, meter/time signature, themes, scripture, CCLI, media/PDF/MIDI links, source illustration, license/attribution |
| Sean McGrath Music | Public original-song catalog and ChordPro files | ChordPro | Yes when supplied | None supplied by this adapter | Source song metadata, media links, CC-BY attribution; original songs only |
| Open Filk Songbook | Public index and per-song source files | ChordPro | When supplied | None supplied by this adapter | Per-song metadata and license/attribution; no blanket assumption that every song has the same license |
| Chordie | Public result and chord sheet pages; file import also available | ChordPro | When supplied | None supplied by this adapter | Source directives and original source link. Blocked pages remain an explicit source failure. |
| Ozbcoz | **File/paste import**, disabled for automatic lookup | From the user's imported document | From the imported document | Singbook timing extensions are retained by the standard song import pipeline when present | ChordPro directives, imported-file provenance. No automated search or site-download success is claimed. |
| Worship Together | **Retired at the owner's request** | Existing imported documents retained | Existing imported documents retained | Existing imported timing retained | Stable source ID and saved provenance are preserved; the source is absent from active provider choices. |
| MusicBrainz | Public recording metadata API; requests paced at least 1.1 seconds apart | No | No | No lyric cues | Recording IDs, artist credits, release identities/dates, duration, ISRCs, work and URL relationships; optional CAA front preview only for a validated exact release/recording relationship; no first-release or release-group fallback |
| Wikidata | Public entity API | No | No | No lyric cues | Composition/performer/writer facts and identifiers from supported claims, provenance, exact Commons-file references when supplied |
| Wikimedia Commons | Exact file-identity metadata lookup, normally after a Wikidata reference | No | No | No lyric cues | Licensed artwork/file URL, creator/credit/license facts. No arbitrary title-based image is presented as recording artwork. |
| Wikisource | Optional public-domain text search and explicit work selection, disabled by default | Historical poem/song text | No | None | Work/author/license/source identity. Historical text is not presumed to match a modern recording. |

## Discovery and combination

When you search, Singbook may send your query to several available song catalogs enabled in settings. It remembers your preferred catalog and shows its results first when available. Otherwise it uses the normal fallback, preferring Genius when configured and available. Wikisource searches historical texts separately and is searched only when you select it. Results that arrive without artwork may be looked up by artist and title in enabled artwork catalogs (Lyrics.ovh and YouTube Music). After you choose a song, Singbook may check enabled sources for lyrics, chords, and metadata. To check a song's key, Singbook may send the chosen recording's Spotify track ID or ISRC (never your account or library) to ReccoBeats (api.reccobeats.com), which returns a key measured from the recording. Provider checks run on device, with three workers, a 30-second provider deadline, 12-second requests and per-host pacing. A source failure is isolated from successful results. Cancellation prevents obsolete requests from being accepted.

Artists, titles, explicit versions, available album distinctions and duration are compared. Missing metadata is not invented. Chord sheets may match the composition without proving the recording; their lyrics are corroborated against fuller matching text when available. The app retains each sheet's own chord positions and never pastes those positions onto another provider's differently worded lyrics.

Combined starts with the fullest matching lyrics, then fills missing chord passages from corroborated arrangements. Matching phrases can span different provider line breaks; the original lyric wording and order stay intact. A partial chart may donate chords after at least 12 shared unique words, 90% chart-word agreement and 75% chart-bigram agreement, even when it omits repetitions or ad-libs. Complete alternatives are tried first. Additional charts need compatible setup and either agreement with existing harmonies or explicit matching setup; ambiguous or conflicting chord placements are skipped. Choosing an individual source still preserves that source's arrangement.

Combined fills missing metadata and deduplicates additive collections such as credits, composers, lyricists and media links. `fieldOrigins` retains each field's primary source and `fieldContributors` records every source that adds collection values. Scalar conflicts, original source documents, attribution and timing alternatives remain preserved. Composition facts do not require recording identity. A matching known album can supply a missing display duration with provenance; this does not establish recording identity or activate timing. Other recording-specific facts still need recording evidence, and key/capo/tuning stay attached to the actual contributing arrangements. Timing retention does not mean it is safe to activate: ordered lyric text and recording identity must agree before a track controls highlighting. Unknown or unsupported timing remains preserved for future interpretation.

Everything travels in one ChordPro `.cho` document with versioned Singbook extensions. The standard body contains lyrics/chords and ordinary metadata; the extensions retain richer provenance and lossless raw timing. No timing sidecar is required. Other ChordPro applications may ignore the extensions.

## Transport and validation

Android uses the Dart-maintained [Cronet HTTP client](https://pub.dev/packages/cronet_http), built with `cronetHttpNoPlay=true` to embed the engine. iOS uses the Dart-maintained [Cupertino HTTP client](https://pub.dev/packages/cupertino_http). These platform clients consume HTTP 103 Early Hints correctly; the Dart IO HTTP/1 implementation failed on Songsterr during desktop testing. Both native clients honor redirect refusal and request cancellation. No app backend, browser automation or credentialed proxy is used.

The unit suites use synthetic fixtures and injected HTTP responses. `test/providers/core/live_smoke.dart` is an opt-in desktop live check; on Windows its test-only curl client avoids the Dart IO Early Hints defect. It prints identity/status/counts, never complete lyrics or tokens. `integration_test/provider_device_test.dart` checks the real mobile transport, all 18 registered routes, raw timing retention and an attributed original-song canary.

Genius needs only a client access token supplied through `config/local.defines.json`; no client secret is used. Public-page and unofficial web integrations can change or be denied independently of catalog API access. A successful fetch is not a universal redistribution license: source-specific attribution and license evidence are retained rather than assigning new rights to fetched content.

## Legal and terms-of-service posture

### YouTube Music access

YouTube Music uses anonymous HTTP requests to unofficial public web-client JSON
endpoints. The exact `https://music.youtube.com` homepage and JSON requests carry
the fixed `Cookie: SOCS=CAI` accept-all consent marker used by
[yt-dlp](https://github.com/yt-dlp/yt-dlp/blob/master/yt_dlp/extractor/youtube/_base.py).
This is an accept-all choice, not a neutral or rejection marker. It
contains no account or device identifier and is not read from, or written to,
a browser or persistent cookie store. It is not sent to artwork hosts or other
providers. Singbook does not open a consent page, sign in, or restore a saved
session. A remaining consent redirect, regional restriction, challenge or
unavailable response remains an ordinary source failure. This is not a Google-
supported lyrics API or a redistribution license. Google OAuth for Drive does
not authorize these requests.

References: [YouTube API resource list](https://developers.google.com/youtube/data/reference/rest),
[Google native OAuth guidance](https://developers.google.com/identity/protocols/oauth2/native-app),
and [YouTube developer policies](https://developers.google.com/youtube/terms/developer-policies).

Singbook is a client that runs on the user's device; it is not a lyrics publisher and has no backend, so every request is made by (and on behalf of) the person using the app.

- **Official or open sources**: Genius (token-authenticated API for the catalog), LRCLIB, MusicBrainz, Wikidata, Wikimedia Commons and Wikisource publish public APIs or open data. WorshipCommons, Sean McGrath Music and Open Filk Songbook publish content under declared licenses (PD, CC-BY, CC-BY-SA, per-file licenses); that declaration, the license URL and the attribution are recorded as `rights` evidence. Even here, the license is the source's statement and has not been independently verified.
- **Unofficial or scraped sources**: Genius song pages (lyrics text), Songsterr, Ultimate Guitar, Chordie, YouTube Music web endpoints, Lyrics.ovh, SyncLRC and Better Lyrics are not offered to apps under a license that allows redistribution of their text, and several have terms of service that restrict automated access. They may be blocked, rate limited or removed at any time. Singbook does not log in or bypass CAPTCHAs, bot walls or paywalls. YouTube Music requests are anonymous; consent interstitials and challenges remain `blocked`.
- **Rights status**: text from these sources is stored with `rights.status = unknown`, the source URL, attribution and a note that no redistribution license is established. Singbook never upgrades that status.
- **Sharing and exporting**: saving a song locally is a personal-use convenience. Sharing, printing, publishing or exporting fetched text (a single `.cho`, collection packages, PDF) is the user's responsibility; check the source's terms and the work's copyright before distributing it. User-imported files keep whatever metadata the user supplied.
- **Remote content is untrusted**: ChordPro from a remote source has any `{x_verse...}` / `{x_verse_data...}` extension directive removed before it enters a song, so a source cannot inject provenance, rights or timing payloads. Artwork, media and original-source links must be `https`, without credentials or non-standard ports, and point at a public host (artwork is further limited to the provider's known image hosts); anything else is dropped.
- **Identification**: requests send `Singbook/<version> (+<contact URL>)`. Set `SINGBOOK_CONTACT_URL` in `config/local.defines.json` so operators such as MusicBrainz and Wikimedia can reach the publisher; no placeholder address is invented when it is unset.
- **Transport etiquette**: per-host pacing, at most two retries for GET requests answered with HTTP 429/503 (honouring `Retry-After` up to 8 seconds; MusicBrainz uses 503 for rate limiting and is reported as `rate_limited`), HTTPS only, and redirects only to the same site (the host or its www/apex twin) with at most three hops. Credentials are never forwarded to another host.
- **Retry-After cooldowns**: numeric values also hold later requests to the same host after cancellation or exhausted retries. Ordinary pacing cannot shorten that cooldown; unrelated hosts remain independent. Optional exact-release artwork and its separate image/rights evidence are described in [artwork qualification](cover-art-qualification.md).
- **Failure codes**: every provider failure reaches the app as a `ProviderException` with a stable `code` (and, for some, a short `message`). Codes the UI can show:
  - `blocked`: a challenge, bot wall or consent page was served instead of the content. The message gives the reason: `cloudflare` (Cloudflare challenge, including `cf-mitigated` responses), `bot_wall` (CAPTCHA or "verify you are human" page) or `consent_required` (cookie/consent interstitial or redirect). No automatic workaround or retry; YouTube Music consent pages are reported as unavailable to the anonymous provider.
  - `rate_limited`: the host answered HTTP 429 or 503 after the transport's bounded retries (MusicBrainz uses 503 for rate limiting).
  - `access_denied`: HTTP 401/403 without a challenge marker (missing/invalid token or the host refuses the request).
  - `redirect`: a redirect that is malformed, leaves the site (host or its www/apex twin) or exceeds three hops.
  - `extraction_failed`: the page was fetched but no longer has the expected layout; the message names the affected candidates.
  - `network`: connection failure or an unexpected HTTP status.
  - `timeout`: the request or provider deadline elapsed.
  - `invalid_response`: the body was missing, malformed, the wrong shape or larger than the allowed size.
  - `unavailable`: HTTP 404, or the source has no lyrics/record for the selection.
  - `provider_busy`: Wikimedia reported `maxlag`; retry later.
  - `ambiguous_match`: more than one possible record, so none was chosen.
  - `identity_mismatch`: the fetched record is not the selected song or recording and was rejected.
  - Selection and input errors: `invalid_query` (empty or over 200 characters), `invalid_selection` (malformed or foreign selection id), `invalid_url` (URL fails the https/host/path policy), `identity_required`, `title_required`, `select_specific_work` (Wikisource disambiguation page), `user_selection_required` (Wikisource needs an explicit work), `rights_review_required` (license not shown as public-domain/open, so text is withheld).
  - Configuration and lifecycle: `not_configured` (no Genius token, or provider not registered), `file_import_required` (Ozbcoz and Worship Together are import-only), `transport_closed`, `cancelled`.
- **Pinning**: WorshipCommons reads its catalog, song files and license links from a fixed commit of `ChurchApps/WorshipCommonsContent`, set by the single constant `WorshipCommonsProvider.contentRef` (currently `d3362e1d7c7f4d3f98b9310bb07aa480453508c7`, the `main` commit of 2026-10-13, resolved 2026-10-15; its `catalog.json` is about 3.5 MB and parses with the adapter). Content and licenses therefore change only with an app update, and only entries declared PD / CC-BY / CC-BY-SA with `approved` status are offered. To bump: run `gh api repos/ChurchApps/WorshipCommonsContent/commits/main --jq .sha`, check that `catalog.json` at that SHA is fetchable and `flutter test test/providers/extra` passes, then update the constant, this paragraph and the date. The catalog may be up to 12 MB; a larger file fails with `invalid_response` rather than loading truncated.

### App Store provider decision — 2026-10-19

The owner chose to retain all existing sources and requested no local publication
block. No provider restriction was implemented. This does not establish missing
permissions or predict Apple's review outcome. Existing service/content-rights
uncertainties remain documented above.

Reviewed evidence: Sean McGrath's original songs use
[CC BY 4.0](https://seanmcgrathmusic.com/about/); the pinned WorshipCommons
revision `d3362e1d7c7f4d3f98b9310bb07aa480453508c7` has its own
[licence](https://github.com/ChurchApps/WorshipCommonsContent/blob/d3362e1d7c7f4d3f98b9310bb07aa480453508c7/LICENSE.md).
[Wikidata structured data](https://www.wikidata.org/wiki/Wikidata:Licensing)
is CC0; [Commons reuse](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia)
depends on each file's licence. These permissions do not extend to unrelated
lyrics or recordings. [Open Filk](https://filksongbook.com/info/en/licenses/)
includes restrictive/custom licences; [MusicBrainz API use](https://musicbrainz.org/doc/MusicBrainz_API)
has conditions distinct from its data licences. Preserve attribution and
per-item licence evidence, including when exporting or printing. Working public
endpoints and embedded provenance alone do not establish all reuse rights.
