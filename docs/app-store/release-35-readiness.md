# Release 0.2.21+35 submission draft

Prepared 2026-10-24 from combined source `35f9e3461238bdd30d0f70875a67f40d7fd2ca78`.
This is source preparation, not an App Store Connect inspection or upload approval.
The integration coordinator owns final source selection and release numbering.

## Feature and evidence profile

The draft targets optional Google Drive and iCloud sync, local backup/restore,
streamed search with preferred-catalog ordering and enabled-catalog artwork
lookups, and pinch-to-resize player lyrics. The Google iOS public client has
been created; local Dart/native callback alignment passes. The native CloudKit
bridge and entitlements are present. The combined source built successfully
with `bash scripts/build-ios.sh simulator`; no simulator boot, account login,
cloud transfer, signing or upload occurred in that compile check. Later source
changes require appropriate requalification.

The eight screenshot records in submission.json retain their original hashes
and explicit 0.2.9+23 provenance. They are historical assets, not new release 35
runtime evidence. Review whether they accurately represent the final product;
capture and visually review current iPhone/iPad views for changed features.
Do not rewrite historical provenance to imply a new capture.

## App Privacy draft

Use the SDK-inclusive profile in `../ios-app-privacy.md` for the final archive:

| Data type | Purpose | Linked | Tracking |
| --- | --- | --- | --- |
| Name, Email Address, Phone Number, Coarse Location | App Functionality | Yes | No |
| Other Data Types, User ID | App Functionality; Analytics | Yes | No |
| Device ID, Other Usage Data | Analytics | Yes | No |
| Other User Content (Google Drive/iCloud songs, setlists and metadata) | App Functionality | Yes | No |
| Search History (provider queries, including artist/title artwork lookups) | App Functionality | Yes, conservatively through request IP | No on evidence reviewed |

The first eight categories follow the pinned GoogleSignIn-iOS 9.2.0 manifest;
they are conservative SDK declarations, not observations that Singbook reads
every field. The app has no app-owned advertising or analytics implementation.
Provider privacy policies do not establish endpoint-specific tracking with
certainty. Final answers must match the exact embedded SDKs and enabled flows.
Runner declares linked Other User Content and Search History for App
Functionality, tracking false, plus FileTimestamp reason C617.1. Inspect the
signed archive's privacy report and manifests before entering final answers.
Review the public policy for both cloud services, enabled artwork lookups and
request/image-host network data; the recorded 2026-10-19 publication is historical
and has not been rechecked by this preparation task.

## Remaining release checks

- Inspect the current App Store Connect app/version/build state. Do not assume
  the earlier Waiting for Review build or account declarations are unchanged.
- Register/associate `iCloud.org.freevia.singbook` with `org.freevia.singbook`,
  regenerate the iCloud-capable profile, and deploy the reviewed CloudKit
  production record schema. Existing signing identities do not establish these.
- Verify release configuration includes the intended Google iOS ID/callback
  and Genius configuration without committing credentials. Check the final
  signed entitlements, bundle/version/build, export and Apple validation.
- Exercise Google and iCloud using disposable libraries: connect, upload,
  second-client download, concurrent edit/conflict, remote deletion, offline
  retry, disconnect and account/provider switching. Compile and mocked tests
  do not establish live transfers or production CloudKit availability.
- Run current iPhone/iPad runtime and visual checks for changed search, artwork,
  sync and player behavior, including compact/large-text/RTL/theme/orientations.
  Physical iPhone/iPad validation is unavailable and must remain disclosed.
- Resolve the private App Review contact name/phone, distribution territories,
  age rating, trader/account declarations and publisher content-rights answers.
  Use Freevia publicly where Apple permits; legal entity is Freevia EOOD.
  Retain support@freevia.org and free/no-ads/no-IAP owner preferences.
- Retain all sources per owner direction. Permission evidence remains incomplete;
  do not mark content rights verified or promise Apple acceptance on that basis.
- Upload only the final verified 0.2.21+35 artifact, await processing, select that
  build, reconcile review notes/privacy/product copy and submit under the
  coordinator's publication workflow. This draft makes no ASC changes.
