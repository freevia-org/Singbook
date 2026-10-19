# TestFlight preparation

## Signing

The bundle ID is `org.freevia.singbook`. Use the paid Apple Developer Program
team that owns this explicit App ID and the matching App Store Connect app.
No valid code-signing identities were found on this Mac during the 2026-10-18
review; a signed export remains blocked until the owner configures the account.

1. Add the Apple account in Xcode > Settings > Accounts and select the paid
   team. In Runner > Signing & Capabilities, enable automatic signing and
   select that team. Provisioning and certificate creation require account
   access; no private key or certificate belongs in this repository.
2. Alternatively, copy `ios/Flutter/Signing.example.xcconfig` to the ignored
   `ios/Flutter/Signing.xcconfig` and replace `YOURTEAMID` with the ten-character
   Team ID. Xcode account access is still required. Explicit project settings
   selected in Xcode take precedence over the xcconfig.
3. Confirm `security find-identity -v -p codesigning` and Xcode signing status.
   Let Xcode manage the provisioning profile and distribution signing assets.
4. Set up the local build defines and matching iOS Google OAuth client as
   described in [iOS setup](ios-build.md) and [OAuth setup](google-oauth-setup.md).
   Empty example values disable Genius and sync; a file's existence alone does
   not establish that these features are configured.

`ios/ExportOptions.plist` uses automatic signing and `app-store-connect`, with
`destination=export`. It creates a local IPA; it does not upload it. Automatic
build-number management is disabled so Xcode preserves the repository version.
The current version is `0.2.8+22`; check App Store Connect for previously used
build numbers before uploading. For a new release, follow AGENTS.md and update
all four version locations together. Rebuilding the same release keeps its number.

```sh
export PATH="/Users/tony/development/flutter/bin:$PATH"
bash scripts/build-ios.sh archive  # unsigned archive for local inspection
python3 scripts/inspect-ios-privacy.py build/ios/archive/Runner.xcarchive
bash scripts/build-ios.sh ipa      # signed archive + local App Store Connect IPA
```

An unsigned archive is not installable or uploadable. After a signed archive
exists, open it in Xcode Organizer, generate the privacy report, validate the
app, and resolve any signing or App Store validation errors. Uploading through
Organizer or Transporter is a separate publishing action. This preparation
does not upload a build or change App Store Connect.

## Privacy manifest review — 2026-10-18

Reviewed application source, resolved native plugin source, and manifests
bundled in the unsigned device app using Flutter 3.44.8 / Xcode 27.1.

| Component | Finding and disposition |
| --- | --- |
| Runner | `lib/application/file_actions.dart`, `_sweepShareDirectories`, reads modification timestamps to delete old app-owned temporary share directories. The app manifest declares FileTimestamp reason `C617.1` for app-container access. It is explicitly included in Runner's Copy Bundle Resources. |
| Flutter engine | Its own bundled manifest declares FileTimestamp (`0A2A.1`, `C617.1`) and SystemBootTime (`35F9.1`). These declarations remain in Flutter.framework. |
| Google sign-in dependencies | GoogleSignIn, GTMSessionFetcher, and GoogleUtilities supply their own UserDefaults declarations. GoogleSignIn also declares collected data. Retain their resource bundles in the final archive. |
| Other native plugins | Bundled manifests exist for file_picker, google_sign_in_ios, package_info_plus, share_plus, sqflite_darwin, url_launcher_ios, and wakelock_plus. |
| Printing | No printing-specific manifest is bundled. Its iOS Swift sources were searched for file timestamp, UserDefaults, boot-time, and disk-space APIs; no calls in those categories were found. This search is not a substitute for Apple's archive validation. |
| App preferences | SQLite-backed; no app-owned UserDefaults or disk-space queries were found. Dart timers/Stopwatch do not alone establish additional app-owned native required-reason API calls. |

The root manifest declares Search History for App Functionality, linked to the
user conservatively through provider request IP/identifiers, and not used for
tracking based on the reviewed integration. Provider policies establish that
some requests are retained beyond the immediate response. The detailed
[App Privacy assessment](ios-app-privacy.md) records the evidence, SDK-inclusive
answer set, and endpoint-specific uncertainties. SDK declarations remain in
their own bundles. The manifest is not the App Store Connect questionnaire.
Before enabling Drive in a distribution build, add Other User Content for
App Functionality, linked to the account, to Runner's collection declarations.
The IPA helper enforces this declaration when the local iOS OAuth client ID
is configured. It does not infer or populate privacy answers from credentials.

The pre-change bundle contained 17 SDK/plugin manifests and no app manifest.
`scripts/inspect-ios-privacy.py` checks that the built root manifest matches the
reviewed source, parses every bundled privacy plist, and prints a repeatable
inventory. It does not certify privacy policy accuracy or App Store compliance.

After finalizing Runner's Search History and FileTimestamp declarations, an
unsigned `0.2.6+20` archive rebuilt successfully. Inspection confirmed bundle ID
`org.freevia.singbook`, minimum iOS 15.0, 18 parseable manifests, and exact
source-to-bundle equality for Runner's manifest. The final inventory, build log,
and SHA-256 records are saved locally in ignored
`artifacts/ios-preparation/testflight-final-privacy-inventory.json`,
`testflight-final-archive-build.log`, and `testflight-final-sha256.txt`. The
previous archive is preserved in `artifacts/ios-preparation/archives/`. No signed archive
or IPA has been produced; signing account setup is still required.
The local `xcodebuild -exportArchive` attempt with `ios/ExportOptions.plist`
stopped with `No Team Found in Archive`. A new archive must be built after
selecting the team; editing export options cannot repair an unsigned archive.

Apple references checked for this review:

- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Required reason API declarations and per-bundle responsibility](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [API categories and approved reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- [Flutter iOS distribution](https://docs.flutter.dev/deployment/ios)

## Before TestFlight upload

Review the privacy report generated from the signed archive against actual
enabled features. GoogleSignIn's manifest lists name, email, phone number,
coarse location, user/device identifiers, other data, and usage data, with
functionality and/or analytics purposes. Confirm which apply to this app's SDK
configuration with Google's current disclosures. Search queries go to remote
content providers, and optional sync stores library content in the user's Drive;
evaluate those flows when completing App Privacy and the public policy. Do not
submit a blanket "Data Not Collected" answer from the local-first design alone.

App Store Connect also needs the correct app record, agreements, export
compliance answers, beta description, contact details, and test instructions.
Test OAuth callbacks and Drive sync with the distribution build, plus import,
export, PDF printing, phone/tablet layouts, and supported locales. The macOS
golden differences were resolved on 2026-10-19 with reviewed
host-specific baselines; see the follow-up verification below.

Prepared materials: [submission fields](testflight-submission.md),
[App Privacy assessment](ios-app-privacy.md),
[policy publication corrections](ios-privacy-policy-changes.md), and
[simulator E2E procedure/results](ios-e2e.md).


## Archive refreshed after phone/tablet QA — 2026-10-19

The unsigned release archive was rebuilt after the native iPhone landscape
navigation fix. Flutter App Settings Validation confirmed `0.2.6 (20)`,
`org.freevia.singbook`, deployment target 15.0. The privacy inspector passed
again: all 18 bundled manifests were inventoried and Runner's root manifest
exactly matched the reviewed source. Signing remains unavailable pending the
Apple Developer team; no IPA upload was attempted.

Evidence: `artifacts/ios-phone-ipad-20261019/final-unsigned-archive.log`,
`final-privacy-inventory.json`, and `final-archive-record.json`. The Runner
executable SHA-256 is
`5d4e80a0e32a3ae8be06580dbb316571f0444d6a9ff480319d65b0fa2012b459`.
The previous verified archive was preserved at
`artifacts/ios-preparation/archives/Runner-before-navigation-fix.xcarchive`.
The [updated simulator QA record](ios-e2e.md#native-iphone-and-ipad-verification--2026-10-19)
records the completed native import/backup checks and retains the earlier failed attempts.

## App Store publishing handoff — 2026-10-19

Offline preparation targets the existing `0.2.6 (20)` release. No new release
number was created for metadata/screenshots. The current profile has no Google
OAuth client or Genius token, so the production copy does not advertise those
features. No signed build, App Store record or submission exists yet.

### Prepared package

- `docs/app-store/metadata/en-US/`: name, subtitle, promotional text, keywords,
  production description and private review-notes draft, as plain text for
  App Store Connect. English is the initial listing locale; this does not
  claim every in-app language has a translated store listing.
- `docs/app-store/submission.json`: exact version/build, URLs, proposed category
  and SKU, remaining owner fields, screenshot dimensions and SHA-256 hashes.
- `integration_test/ios_store_screenshots_device_test.dart`: reproducible
  native portrait captures of the real library, reader, dark reader and
  setlist UI, using original demonstration lyrics in a temporary database.
  No resized QA screenshot or fabricated interface is used. Sample content
  is for the listing and is not embedded in the normal app library.
- Existing `docs/ios-app-privacy.md` and `docs/ios-privacy-policy-changes.md`:
  source/SDK-based App Privacy answers and public-policy corrections.
- Existing export options, optional local signing xcconfig, unsigned archive,
  privacy inspector and simulator QA evidence. Root manifest review passed;
  Apple's signed-archive validation remains deferred.

Run `python3 scripts/check-app-store.py` to check version alignment, public
metadata lengths, required screenshot groups/dimensions/RGB format and hashes.
The command validates local materials only and explicitly reports remaining
submission dependencies. Use Apple's live field validation when entering them.

### Content authorization decision

The owner chose on 2026-10-19 to retain all existing sources without a local
publication gate or restricted provider profile. Permission evidence remains
incomplete; this decision does not establish rights or guarantee Apple approval.
The authorization findings are documented in
[the source review](sources.md#legal-and-terms-of-service-posture).
Apple's [Guideline 5.2.2](https://developer.apple.com/app-store/review/guidelines/#intellectual-property)
requires permission under the service's terms for third-party content/services.
Attribution, anonymous access, personal use and a working endpoint do not
establish that permission. No provider rights are asserted by these materials.

| Integration group | Evidence needed for the final App Store profile |
| --- | --- |
| Genius catalog/API vs song-page lyrics | Distinguish API permission from permission to retrieve/save/share lyric text. Token is currently absent. |
| Songsterr, Ultimate Guitar, Chordie, YouTube Music, Lyrics.ovh, SyncLRC, Better Lyrics/Unison | Current written service permission/terms and content rights covering the implemented access and uses; undocumented scraping or public API availability alone is insufficient. |
| LRCLIB | Confirm service permission and rights for lyric storage/export, independently of API availability. |
| WorshipCommons, Sean McGrath, Open Filk | Keep per-song licence and attribution evidence; independently verify the applicable licence and any conditions. |
| MusicBrainz, Wikidata, Commons, Wikisource | Verify API/service rules, required attribution and per-file/text licences. Metadata permissions do not grant lyric rights. |
| Ozbcoz / Worship Together imports | Automatic lookup is disabled; users supply files. Do not claim a commercial catalogue licence from import support. |

All existing integrations retain their current configuration. No restriction or
publishing block was added. Keep available permission evidence and the actual
provider profile in private App Review information; do not assert authorization
where it has not been established.

### Privacy, rating and product-page declarations

- The iOS policy corrections and support guidance were published on 2026-10-19.
  Both URLs returned HTTP 200 and were visually reviewed. The earlier
  client-specific 403 was not reproduced; no security rule was weakened.
  Source HTML and deployment provenance are in `docs/site/singbook/`.
- Enter the conservative SDK-inclusive profile from `ios-app-privacy.md`
  (including Search History for active provider queries). Do not choose
  “Data Not Collected” solely because the library is local or OAuth is off.
  Resolve endpoint-specific tracking/identifier uncertainties before submission.
  If Drive is later enabled, re-review Other User Content, privacy declarations,
  OAuth callbacks and description before signing the release.
- Complete Apple's current age-rating questionnaire from the actual enabled
  sources. Local import and remote lyrics can contain mature language/content;
  no content filter or parental-control claim is made. Account creation, chat,
  gambling, purchases and advertising were not found in this app, but owner
  must answer the live questionnaire and select any required override honestly.
  Do not preassign a 4+ rating from the app's intended music use.
- Confirm content-rights declaration and copyright owner; proposed Music
  category, SKU and manual release still require owner confirmation. Do not
  use placeholder copyright/contact text in public fields.
- Do not declare untested VoiceOver or other accessibility nutrition labels as
  supported. Large-text/dark/RTL simulator checks are evidence of tested screens,
  not a full accessibility certification. Leave unsupported optional claims off.
- For EU distribution, complete the account's trader-status declarations and
  required public business/contact information. Pricing, territories, licence
  agreement choice and Mac/Apple Vision availability need owner decisions.

### When the developer account arrives

1. Confirm team, explicit App ID, app-name/SKU availability and App Store record.
   Check existing build history before using build 20. Account holder completes
   agreements, trader declarations and any required commercial setup.
2. Select the team locally in Xcode or ignored `Signing.xcconfig`. Keep the
   current no-OAuth profile unless a separately validated change is approved.
3. Rebuild a signed IPA with `bash scripts/build-ios.sh ipa`; inspect its privacy
   manifests and Xcode Organizer privacy report. Validate through Organizer and
   resolve actual signing, SDK or App Store processing errors. Rebuilding the
   same release does not itself require a version increment.
4. Upload, wait for processing, enter final privacy/rating/content-rights answers,
   add approved metadata/screenshots and owner review contacts, and select the
   processed build. Review notes must name the actual enabled provider profile;
   remove the preparatory evidence instruction after supplying that evidence.
5. Submit for App Review only after the policy/content decisions are resolved.
   Proposed manual release allows the owner to choose publication after approval.

Physical hardware is unavailable. Native iPhone/iPad simulator tests passed the
recorded app/library, native import, share/print cancellation and backup flows;
no physical device, signed runtime, Face ID/Keychain/OAuth, real printer or
VoiceOver validation is claimed. This is a documented testing limitation rather
than an instruction to obtain hardware before offline preparation can finish.
Apple may identify device-only issues during review; address any actual issue
before release. The earlier four golden differences were resolved with visually
reviewed
macOS baselines; Linux and Windows baselines are unchanged.

References checked 2026-10-19: [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications),
[version metadata](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information),
[product-page guidance](https://developer.apple.com/app-store/product-page/),
[App Review guidelines](https://developer.apple.com/app-store/review/guidelines/),
[age-rating setup](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating),
and [EU trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements).

### Offline package verification

Both original-content capture runs passed on 2026-10-19: four PNGs on iPhone
17 Pro Max (1320×2868) and four on iPad Air 13 M3 (2048×2732), iOS/iPadOS 27.0.
All eight were visually reviewed; the tablet reader was also inspected at
full size. The packaged PNGs retain the original pixels, with only fully opaque
alpha removed for RGB encoding. Native originals and passing runner summaries
are preserved under ignored `artifacts/ios-store-20261019/{iphone,ipad}/`.
No crop, stretch or simulated device-size override was applied.

`check-app-store.py`, focused Dart analysis, Python compilation, and whitespace
checks passed. Existing unsigned archive privacy inspection passed again.
The App Store icon was verified at 1024×1024 RGB. These checks prepare the local
package; they do not substitute for signed-archive/App Store validation.
All subagent work is complete and temporary build/device reservations released.

### Publication follow-up — 2026-10-19

Privacy and support production deployment `51f629dd-4742-448b-9a98-a5c470451e9f`
changed only the two Singbook pages, preserving the other 66 website assets.
The policy covers iOS storage/deletion/backups, bundled Google SDK disclosures,
provider request retention and YouTube visitor identifiers. Support now describes
automatic sync after library changes and manual backup import accurately.

The merged production code at `a8d45f12f8d9dfa881014154d4faa3f33db27cbd`,
including the newer provider-version replacement change, was archived unsigned
as `0.2.6+20`. Inspection found 18 privacy manifests, bundle ID
`org.freevia.singbook`, minimum iOS 15.0. Evidence is under
`artifacts/ios-merged-20261019/`; the previous archive was copied before rebuilding.
This archive cannot be uploaded or installed without signing.

Five macOS golden baselines were visually reviewed for chord collisions, wrapping,
RTL and landscape rendering. All 12 focused chord/lyric tests passed without
updating goldens during verification. Linux/Windows baselines and geometry
expectations are unchanged. No app features or source restrictions were added.

Merged archive Runner SHA-256: `ce2f7e22c245e03b0bd96441aba4487803c2048062561c2115a42ed59978dee9`.

Full Flutter unit/widget suite passed: **1,270 tests**, including the macOS
goldens, with no golden-update flag. Log:
`artifacts/publication-gates-20261019/all-tests.log`. Focused Dart analysis,
store package validation and whitespace checks also passed. These checks do
not add new physical-device or signed-build testing claims.

### Android/iOS parity candidate — 2026-10-19

The current candidate is `0.2.8+22`, integrated from upstream `dbb3ff5`; earlier
archive and screenshot records above refer to their historical source versions.
The latest shared UI, timing, setlist and source-metadata changes run on iOS.
The Android-only Drive Picker gap has an iOS system-browser/Keychain adapter;
its account/scope/PKCE/state checks reuse the tested grant implementation.
Live Google consent and token refresh still require configured iOS OAuth and
remain unperformed. Signing and physical-device limitations remain unchanged.

The privacy/support pages were refreshed in production deployment
`a4f6548a-fcde-4b74-a622-e24dcad62f4a`, preserving the other 70 site assets.
Both returned HTTP 200; the live iOS Picker/Keychain text was verified.

The unsigned `0.2.8+22` release archive built successfully from source commit
`a0df607`. Privacy inspection confirmed 18 manifests, bundle ID
`org.freevia.singbook`, and minimum iOS 15.0. Evidence is in
`artifacts/ios-parity-20261019/{archive-build.log,privacy-inventory.json,archive-record.json}`.
The previous archive is preserved as `Runner-before-parity.xcarchive` there.
Runner SHA-256: `86807db89d8ada30a7f2fd094d9bd3f5a55156bc9141dbfadaf358b4c98df46c`.
The complete host suite passed 1,531 tests with 13 platform-specific skips;
both native parity runs passed six tests. No signed IPA, physical-device test
or live Google OAuth validation is claimed. All temporary reservations are released.
