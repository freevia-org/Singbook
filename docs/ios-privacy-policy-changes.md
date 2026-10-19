# Privacy policy corrections for the iOS beta

Local publication draft, reviewed 2026-10-18. The public policy is reachable,
but still describes Android only. Apply the approved wording consistently to
the Markdown, HTML, public policy, and translated summaries before iOS beta
distribution. This file does not publish or replace the current policy.

## App and local storage

Replace the app identity line with:

> App: Singbook (Android package and iOS bundle ID `org.freevia.singbook`).

Replace the platform-specific local-storage and token descriptions with:

> Singbook stores your library and settings in the app's private storage on
> Android or iOS. The operating system protects this storage with its app
> sandbox; Singbook does not add a separate encryption layer to its database.
> System backup and device transfer may include app data according to your
> device and backup settings. Such backups are managed by the operating system
> and backup provider, not by Freevia. Files you export, print, or share go to
> the destination you choose through the operating system.

> Google sign-in is optional. The app remembers your Google account identifier,
> email, and profile-photo URL locally to restore the session and display the
> selected account. It fetches the profile image from Google's image host.
> Google's sign-in libraries manage authentication on the device. Singbook does
> not write access tokens into song files or send tokens to Freevia.

Keep Android backup exclusions explicitly scoped to Android. Do not claim
that the existing Android exclusions configure iOS backup behavior. iCloud
library sync is unavailable; an operating-system device backup is a different
feature.

## Provider identifiers and logging

Replace the absolute claim that no device identifiers are sent with:

> Provider requests send your search text or the requested song's title,
> artist, album, and other matching metadata, along with normal network
> information such as your IP address and a Singbook User-Agent. Singbook does
> not attach your Google Drive account identity to song-provider searches.
> The YouTube Music adapter obtains a Google-issued visitor value from the
> service and sends it back as `X-Goog-Visitor-Id` on subsequent requests. This
> is separate from the fixed `SOCS=CAI` consent marker and from an advertising
> identifier. No signed-in browser cookies are imported.

> Providers may retain queries and request logs beyond the immediate response,
> derive approximate location from IP addresses, and use service identifiers
> under their own policies. Their policies differ. Freevia does not receive
> these requests or control upstream retention. Turning off sources reduces
> which services receive requests.

The catalog also uses Unison (`unison.betterlyrics.org`; legacy attribution references `unison.boidu.dev`) and can refresh source
definitions from the public GitHub repository; include the actual release
catalog hosts in the provider table. Preserve the existing accurate explanation
that `SOCS=CAI` represents an accept-all choice rather than a rejection choice.

## Google SDK and App Privacy

Add a disclosure scoped to the configured Google sign-in feature:

> Google's iOS sign-in SDK discloses collection for authentication and fraud
> prevention. Its bundled privacy manifest also declares linked identifiers,
> contact/profile data, approximate location, and usage/other data with
> functionality or analytics purposes. These are Google's SDK disclosures;
> Singbook has no publisher-operated analytics or advertising service. The
> App Store privacy answers account for the integrated SDK and enabled
> providers as well as Singbook's own code.

Resolve the manifest/prose discrepancy described in `ios-app-privacy.md`
against the exact release configuration. Avoid equating "the publisher does
not receive data" with "the app and all partners collect no data". Reword the
children section and translated summaries so they do not make an absolute
no-collection claim while network requests and third-party collection exist.

## Deletion on iOS

Add alongside the existing Android instructions:

> On iOS, delete songs or setlists in the app to remove those local records.
> Deleting the app removes its local app data; offloading an app may preserve
> that data. Manage device backups in Apple's device/account settings. Removing
> the app does not remove exported files or the copy in Google Drive. Use the
> Google Drive deletion and access-revocation steps below to remove that copy.

Keep the current Drive removal instructions, public privacy contact, and
publisher details. The policy effective date must reflect the eventual approved
publication, rather than implying this local draft is already live.

Sources and data-flow evidence are collected in `ios-app-privacy.md`. This
draft does not establish upstream provider retention for undocumented APIs.
