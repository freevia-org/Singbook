# Manual 0.2.26 Google Play gallery capture

Run the `Capture Singbook Play gallery (0.2.26)` GitHub Actions workflow only
after its source PR is reviewed and merged. It checks out release tag
`v0.2.26` (`1120fc1e0faf3d0e59435390d9fb1fdaa13174ac`), verifies the
published APK hash, then builds the actual release-source UI with a test-only,
isolated SQLite library on a fresh Android emulator. The signed APK is **not**
the executable that renders these screenshots. The capture therefore proves
source-version UI, not binary identity. The workflow cannot publish or change
the app or its Play listing. A human must inspect every image before upload.

The two sample songs use a short line each from human-authored public-domain
works. `Auld Lang Syne` is credited to Robert Burns, with four short lines
transcribed from the [Library of Congress article on Burns's text](https://blogs.loc.gov/folklife/2013/12/auld-acquaintance-for-the-new-year-burnss-auld-lang-syne/). The [LOC 1900 edition](https://www.loc.gov/item/00001778/)
confirms the work is public domain. `Amazing Grace` is credited to John Newton and its 1779 text is
described in the [Library of Congress collection](https://www.loc.gov/collections/amazing-grace/articles-and-essays/dissemination-of-amazing-grace.html/).
The second sample contains only its first short line. Chord letters are generic UI
demonstration notation, not a modern arrangement. No cover art, modern
recording, online result, private library, or test-only provider is included.

The raw 1080×1920 artifact contains these checkpoints:

1. `01-library-device.png` — two saved public-domain songs.
2. `02-local-search-device.png` — local library filtered to Auld Lang Syne.
3. `03-reader-device.png` — chord-over-lyric reader and player controls.
4. `04-setlists-device.png` — saved two-song rehearsal setlist.
5. `05-appearance-device.png` — actual appearance settings.

The tagged Android Gradle build exposes `singbookFixtureE2e` as a Debug-only
opt-in. The capture script sets it via `ORG_GRADLE_PROJECT_singbookFixtureE2e`
to exclude the `cronet-shared` dependency during this isolated test build;
without it, Android Gradle Plugin 9 rejects duplicate `org.chromium.net`
namespaces from `cronet-api` and `cronet-shared`. Release dependency packaging
is not changed. The capture does not exercise online providers.

The artifact also includes SHA-256 hashes, the Flutter test log, and native
full-device PNGs. Android status/navigation bars are part of the originals.
Any later crop or color conversion needs separate pixel-level verification and
its own provenance. The works are human-authored; the app icon may still
require a separate AI-asset label based on its own origin.
