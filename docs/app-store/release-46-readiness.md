# iOS packet refresh for 0.2.32+46 (draft)

Prepared 2026-10-30 from main `851900e`. Source preparation only: nothing was
built on iOS, signed, uploaded to App Store Connect or TestFlight, or
submitted. Those steps are human-gated. This supersedes the version/build
numbers in `submission.json` (0.2.22+36) and `release-35-readiness.md`; the
carried-over open items in that file still apply. It does not rewrite
historical screenshot provenance (0.2.9+23).

## State to reconcile
- Apple is still reviewing 0.2.25+39. Nothing newer is on the App Store.
  Confirm current App Store Connect state before choosing a build number.
- Main is 0.2.32+46. Android parity for iOS depends on draft PR #263
  (rich clipboard channel, Drive folder and ChordPro import controls).
- Localization: 34 ARB files match the 34 `CFBundleLocalizations` entries.
  Re-check both after any ARB change. The App Store description is en-US only.
- Privacy: follow `docs/ios-app-privacy.md`. Runner manifest declares linked
  Other User Content and Search History (App Functionality, no tracking) and
  FileTimestamp reason C617.1. Inspect the signed archive's privacy report
  before entering final answers.

## Metadata
`docs/app-store/metadata/en-US/*` (name, subtitle, description, keywords,
promotional text, review notes) predates features added since 0.2.22. Review
and update before submission:
- Description and review notes: Google Drive visible-folder picker and
  ChordPro Drive import on iOS, rich-text copy, enabled sources and artwork
  lookups, iCloud sync. State that all sources stay enabled by owner decision
  and that content-rights permission evidence is incomplete.
- Review notes must name how a reviewer exercises Drive and iCloud sync
  without the owner's account (disposable account or demo steps).

## Screenshot plan (fresh capture needed, on the Mac)
Existing sets (iPhone large, iPad 13") are historical. Capture current views
and review them visually, for 6.9" iPhone and 13" iPad:
1. Library with search results and source/artwork chips
2. Reader/player in light and dark, including large lyric text
3. Setlists
4. Settings > Account with Drive folder and sync controls (new on iOS)
5. One localized set (for example Ukrainian or Arabic RTL) for QA, not
   necessarily for the listing
PR #230 holds the existing screenshot-capture workflows.

## Still human-gated or open
- iCloud container `iCloud.org.freevia.singbook`, profile and production
  CloudKit schema; Google iOS client in the release configuration
- Live disposable-library sync tests (Google and iCloud)
- Physical iPhone/iPad validation (unavailable so far)
- App Review contact, territories, age rating, trader/account declarations
- Signing, archive validation, upload, build selection, submission
