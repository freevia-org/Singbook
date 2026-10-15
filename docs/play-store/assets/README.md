# Google Play listing assets

Prepared for the Singbook 0.2.0 release. The phone screenshots are English app
screens from the completed device journey and use the app's original
`Lanterns at Dawn` test fixture, not a third-party song. They have been cropped
to remove Android status/navigation bars and fit Google's 9:16 phone format;
their UI and text are otherwise unchanged.

| File | Size | Suggested alt text |
| --- | --- | --- |
| `app-icon-512.png` | 512 × 512, 32-bit PNG with alpha, 163 KB | Singbook's open songbook icon with chord markings and a large amber musical note. |
| `feature-graphic-en.png` | 1024 × 500, 24-bit PNG | Singbook's chord sheet pairs varied chord positions with stylized lyric lines. |
| `feature-graphic-bg.png` | 1024 × 500, 24-bit PNG | Singbook показва акорди, разположени сред стилизирани редове от текст. |
| `feature-graphic-uk.png` | 1024 × 500, 24-bit PNG | Singbook показує акорди, розташовані серед стилізованих рядків тексту. |
| `phone-01-library.png` | 1080 × 1920, 24-bit PNG | Singbook's recent-song view, with search, favorites, and the personal library. |
| `phone-02-reader.png` | 1080 × 1920, 24-bit PNG | The Singbook reader displays an original sample song with chords above lyric lines and playback controls. |
| `phone-03-source-preview.png` | 1080 × 1920, 24-bit PNG | A Singbook song match preview showing lyric, chord, timing, and recording-match details. |
| `phone-04-themes.png` | 1080 × 1920, 24-bit PNG | Singbook appearance settings show theme, palette, font, and reader text-size options. |
| `tablet-large-library-light.png` | 1280 × 800, 24-bit PNG | Singbook's tablet library shows a searchable, multi-column song collection. |
| `tablet-large-reader-light.png` | 1280 × 800, 24-bit PNG | The tablet reader shows chords interspersed with lyric lines and persistent playback controls. |
| `tablet-large-reader-dark.png` | 1280 × 800, 24-bit PNG | The same song reader in Singbook's dark navy theme with amber chord accents. |
| `tablet-large-settings-light.png` | 1280 × 800, 24-bit PNG | Singbook tablet appearance settings show language, theme, palette, font and text-size controls. |

The app icon is a high-resolution listing export of the approved launcher art;
it does not replace Android's adaptive launcher icon. Feature graphics use
Singbook's blue, navy, parchment and amber palette, with a chord-sheet motif
that extends the wordmark instead of repeating the app icon.

The Play Console can use the English, Bulgarian and Ukrainian feature graphics
with their matching listing locales. The current phone screenshots use English
UI. Google recommends localized screenshots when the listing is localized, so
capture Bulgarian and Ukrainian screen sets before promoting the listing in
those locales.

The four large-tablet screenshots are English landscape captures from the
0.2.0 UI, rendered by `test/ui/visual_tablet_capture_test.dart` at 1280 × 800.
They use only the test's fictional sample songs and contain no third-party
lyrics. The provided Xiaomi Pad is 2880 × 1800, but Android blocked installing
the temporary capture build (`INSTALL_FAILED_USER_RESTRICTED`), so these are
test-rendered UI images rather than native captures from that tablet. Review the
screens on the physical tablet before uploading them. The older tablet captures
in local test artifacts display version 0.1.3 and are stale.

Before uploading, confirm the package and screenshots still match the final
release and enter alt text in Play Console. The publisher/contact and privacy
URL in the listing and policy docs are already set to Freevia's public details;
recheck them against the live pages if either changes.

Official requirements: [Play preview assets](https://support.google.com/googleplay/android-developer/answer/9866151)
and [store listing setup](https://support.google.com/googleplay/android-developer/answer/9859152).
