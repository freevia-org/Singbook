# LyricsPlus channel 7 candidate

This candidate adds `config/source-catalog-v7.json`, revision 19, with 28
entries. Its first 27 source entries are retained from channel 6 without
changing their data or Unicode text. The only new entry is the native
LyricsPlus adapter, revision 1, active and enabled by default for compatible
channel 7 clients. Catalog channels 1 through 6 remain untouched.

The client selects the v7 asset, endpoint and `sourceCatalog:v7` cache. All
older assets and cache keys remain available. The existing bounded cache
migration reads the closest valid previous channel first, starting at v6;
an older channel's larger envelope revision cannot exclude the new adapter.
Source repairs from that previous cache can remain available offline until
an authoritative current-channel refresh commits. Provider opt-outs and
saved documents remain independent of the catalog channel.

LyricsPlus search rows are lookup hints. The native resolver reads actual
lyrics and independently checks the returned Apple platform ID through the
official lookup API. It retains actual source metadata, attributed provenance,
original JSON and line/word timing, with no recording identity or audio
alignment claim. Per-work lyric rights remain unknown. Other winning
upstreams require separate native qualification; this catalog does not imply
support for them.

The two catalog probes search Billie Jean / Michael Jackson and Creep /
Radiohead. Each requires body, metadata, line timing and word timing, including
independent Apple metadata fields. The existing local native and ordinary
maintenance CLI evidence is described in
[`lyricsplus-source-qualification.md`](lyricsplus-source-qualification.md).
No extra live requests were made to prepare this channel.

The new regression tests exercise both probe contracts through synthetic
search, lyrics and independent metadata responses, reject a v7 update on a
roster without the native adapter, preserve all prior entries, and cover
bootstrap, opt-out and populated-library upgrade behavior. Thirty focused
channel/cache tests and 1,484 combined provider/domain/application/chord-only UI
tests pass, scoped analysis is clean, and independent read-only review found no
concrete compatibility defect. The ordinary default offline CLI validates all
28 entries with no registry/catalog gap. The previously live-probed LyricsPlus
runtime/probe configuration is unchanged; only its change-reason text differs.

App/device qualification, native PR integration, publication, cloud reachability
and a compatible app release remain explicit gates. These local checks do not
claim those outcomes.
