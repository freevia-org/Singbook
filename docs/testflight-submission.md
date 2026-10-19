# TestFlight submission details

Draft metadata for the first external TestFlight beta. Confirm every owner field
and re-check feature availability against the exact signed build before entry.
The current repository version is `0.2.6+20`. The unsigned archive passed its
18-manifest inspection, and the simulator target passed eight tests with one
missing-Genius-token skip; see [E2E evidence](ios-e2e.md). No signed IPA or
physical-device OAuth build has been verified. Native document/share/print cancellation and a local Files export/import
round trip also passed on 2026-10-19. Physical-device checks, real printer
output, and the public policy corrections remain release gates.

## App record

| App Store Connect field | Value |
| --- | --- |
| Name | Singbook |
| Bundle ID | `org.freevia.singbook` |
| SKU | Proposed `singbook-ios`; check uniqueness in the owner's account before creating the permanent record |
| Primary language | English (U.S.) (`en-US`) |
| Platform | iOS |
| Version / build | `0.2.6` / `20` (confirm against uploaded archive and App Store Connect history) |
| Support URL | `https://freevia.org/singbook/support/` |
| Privacy Policy URL | `https://freevia.org/singbook/privacy/` |
| Beta marketing URL (optional) | `https://freevia.org/singbook/` |

The app name, bundle ID, current version and links are traced to `README.md`,
`pubspec.yaml`, and `docs/ios-testflight.md`. The Play listing identifies the
category as Music & Audio; choose Apple's closest available category when the
owner creates the record. The proposed SKU has not been registered; its uniqueness and the
account-owned contact details require the owner’s account.

Original fictional import samples are prepared in
`docs/testflight-fixtures/lanterns.cho` and `lanterns.lrc`. Supply them to the
beta group through the chosen tester distribution channel. The app does not
ship a prepopulated song library, and these files are not embedded in the build.
Complete Apple's age-rating questionnaire against the enabled provider content
and import features; this draft does not assign an unverified age rating.

## TestFlight test information

### Beta App Description

```text
Singbook is a local-first songbook for musicians and singers. Search song sources, compare lyrics and chord arrangements, keep songs and setlists on your device, and use them at rehearsal or on stage. Import and export portable ChordPro files, transpose chords, follow timing where a source provides it, and print or save a song as PDF. The app works without a Singbook account. Google Drive sync is optional and appears only in builds configured for Google sign-in. This is a beta: some third-party sources may be unavailable or return different results, and sync availability depends on the build configuration.
```

This avoids promising that OAuth or live providers work in the submitted build.
The repository documents those flows, but says their iOS distribution-build
behavior remains unverified (`README.md`, `docs/ios-build.md`,
`docs/ios-testflight.md`). Remove or revise the sync sentence if the build cannot
show the feature, and update the description if beta scope differs.

### Feedback Email

```text
[OWNER: enter a monitored feedback email address]
```

`support@freevia.org` appears as the public Play listing contact in
`docs/play-store/listing.md`, but this document does not assume it is the
owner-approved TestFlight feedback address. Apple uses this address in TestFlight
and as the reply-to address for invitation emails.

### What to Test

```text
Please test the core library without signing in:
- Import a song into the empty library, open it, and check chord and lyric readability in light and dark appearance.
- Search for a song and compare available results. Report sources that fail, return no results, or show mismatched lyrics or chords; provider availability can vary.
- Import a ChordPro file and a plain-text or LRC lyrics file. Edit a song, transpose it, then export/share the ChordPro file and confirm its content is intact.
- Create and reorder a setlist, open songs from it, and try PDF printing or saving.
- Try large system text, VoiceOver, a phone and an iPad if available, and portrait and landscape layouts.

Google sign-in and Drive sync are optional and may not be configured in this beta. If the Sync screen says the feature is not configured, skip that flow and report the message. Please include device model, iOS version, steps to reproduce, and a screenshot when useful. Do not include private song content in feedback.
```

The app has no required account for its local library. No demo credentials are
available or needed. Testers should not be told to sign in with a publisher
account. If the submitted build enables optional Google sign-in, test with a
separate owner-controlled test account and document the actual flow before
submission; never put personal credentials in public beta metadata.

## Beta App Review information

For external testing, Apple requires Test Information including a beta app
description and feedback email. Apple's current TestFlight overview says the
first build added to an external tester group is sent to App Review; subsequent
builds may not need a full review. This is distinct from App Store distribution
review, and approved App Store screenshots/category can optionally appear in
the invitation.

| Review field | Entry |
| --- | --- |
| Contact name | `[OWNER: legal/operational review contact]` |
| Contact email | `[OWNER: monitored review contact email]` |
| Contact phone | `[OWNER: reachable international-format phone number]` |
| Sign-in required | No, for core app use |
| Username / password | Leave blank; local library does not require login |
| Notes | `Singbook's song library works without an account. Google sign-in and Drive sync are optional and depend on OAuth configuration in this build. If Sync reports that it is not configured, review the local library, import/export, setlist, and search flows without signing in. Search results come from third-party services and can vary by network, region, and provider availability.` |

App Review contact fields are owner-required. If optional Google login is
enabled and blocks access to any feature under review, provide valid, durable
demo-account credentials and any required authentication-code instructions in
the private App Review fields. Otherwise, keep login marked as not required.
Never place credentials in this public repository or tester-facing description.

## Remaining owner decisions

### Export compliance entry to verify

`ios/Runner/Info.plist` currently sets `ITSAppUsesNonExemptEncryption=false`.
The source uses HTTPS through native networking and hashes for content identity;
no custom file encryption or encrypted database implementation was found.
Apple says operating-system encryption such as URLSession HTTPS is typically
exempt from documentation upload. Confirm the final app and all linked SDKs
still fit that exemption before keeping this value; it means **no non-exempt
encryption**, not "no encryption anywhere."

References: [Apple encryption compliance](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations)
and [export compliance overview](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance).

### Account and release fields

- Create/confirm the paid Apple Developer team, explicit App ID, App Store
  Connect record and permanent SKU; configure signing. The local review on
  2026-10-18 found no signing identity, and no signed IPA exists.
- Confirm App Store Connect has no conflicting prior version/build and upload
  the archive matching `0.2.6 (20)`; increment versions in all repository
  locations for a genuinely new release, not a rebuild.
- Supply the feedback email and App Review name, email, and phone; confirm who
  will monitor them.
- Decide whether OAuth is configured in the submitted build. If enabled,
  perform physical-device sign-in and Drive sync checks and provide private
  reviewer access only if required. Validate which live providers actually
  respond on the distribution build.
- Complete the App Privacy questionnaire from a full collection assessment.
  Use `docs/ios-app-privacy.md` for the source-based assessment and proposed
  data-type answers; the Play policy is a source for review, not proof of the iOS
  answers. The public home, privacy, and support URLs returned HTTP 200 on 2026-10-18; review their wording against the final enabled features.
- Answer export compliance for the actual archive and resolve archive/App Store
  validation results. The unsigned local archive is not uploadable.
- Confirm the beta description and What to Test against the exact build and
  supported test scope before inviting external testers.

## Apple field and review references

- [Provide test information](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/): external-test metadata requirements and invitation behavior.
- [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/): first external build review, tester flow, feedback and 90-day build period.
- [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information): App Store version metadata and separate App Review information; review notes allow up to 4000 bytes.
- [Complete review](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review): provide valid demo credentials when account features require them.
- [Beta app localization attributes](https://developer.apple.com/documentation/appstoreconnectapi/betaapplocalization/attributes-data.dictionary): beta description, feedback email and optional URLs.

Apple's current TestFlight help and API pages reviewed here do not state a
character maximum for Beta App Description, What to Test, or Feedback Email.
Use App Store Connect's live field validation rather than relying on old
third-party limit tables. The 4000-byte limit documented for App Review Notes is
a different field and should not be applied to those beta fields.
