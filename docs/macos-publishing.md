# macOS publishing

Singbook has a native Flutter macOS target with bundle ID
`org.freevia.singbook`, macOS 12 or later, and the same SQLite database name,
ChordPro payloads, timing and provenance as the other platforms. macOS uses
sqflite's native backend. Move libraries between installations using explicit
library backup export/import; never copy an open SQLite database or clear a
user's installation to fix signing.

## Build and signing

Use Flutter 3.44.8 / Dart 3.12.2, full Xcode and the locked dependencies.
The app is sandboxed in Debug, Profile and Release. Network clients,
user-selected read/write files and printing are enabled. Debug/Profile also
retain Flutter's JIT and incoming development connection entitlements. Release
has hardened runtime enabled and no JIT entitlement.

Copy `macos/Runner/Configs/Signing.example.xcconfig` to the ignored
`Signing.xcconfig` next to it, set the owner's Apple Developer team, and select
`CODE_SIGN_IDENTITY = Apple Development` for local development. Google sign-in
Keychain groups require a provisioning profile even when OAuth is disabled.
Xcode must be signed into the owner's developer account. The build script
does not request provisioning updates or device registration, so missing
profiles fail the build instead of creating signing authority; credentials and
profile data are never stored in source control.

```sh
# Ensure flutter 3.44.8 is on PATH first
bash scripts/build-macos.sh release
bash scripts/build-macos.sh debug
```

Each build creates a unique directory below ignored `artifacts/macos/` with
the app, build log, source revision/diff/status, version report and SHA-256 of
the local preview ZIP. Commit the source before creating a final publishing
artifact so the revision identifies the complete implementation. The preview
ZIP is for local validation; it is not a notarized distribution.

## Google Drive and online sources

Copy `config/defines.example.json` to ignored `config/local.defines.json`.
For macOS Google sign-in, follow the endorsed plugin's iOS/macOS registration
instructions using bundle ID `org.freevia.singbook`. Supply its client ID as
`VERSE_GOOGLE_MACOS_CLIENT_ID`. Copy `Secrets.example.xcconfig` to ignored
`macos/Runner/Configs/Secrets.xcconfig`, set `GID_CLIENT_ID` to the same ID and
`GID_REVERSED_CLIENT_ID` to the ID's reversed components. The build preflight
checks their alignment without printing their values. Do not use the Windows
desktop OAuth client for this native SDK flow.

Primary sync uses `drive.appdata`. The explicit visible-folder/file Picker
action uses a separate `drive.file` grant, state and S256 PKCE through
`ASWebAuthenticationSession`. File grants are account-bound and stored in
non-synchronizing macOS Keychain items; the native Google SDK manages primary
sign-in credentials in its own Keychain groups. Sign-out clears the separate
file grant. Neither scope is requested by background work without a previous
explicit connection. A build without the macOS client leaves sync unavailable.
Genius also requires the existing local build configuration.

Real Google consent, refresh, revoked access, account switching, Picker
cancellation, restart and sign-out must be accepted using the owner's test
account before publishing a configured build. Mocked tests do not establish
Google console registration or live OAuth acceptance.

## Mac App Store

Use the existing Singbook App Store Connect record's macOS platform when
available, retaining the bundle ID. Enable macOS on the registered App ID and
configure the appropriate Mac development/distribution profiles. App Store
export needs an application distribution certificate and Mac Installer
Distribution certificate with private keys in the owner's Keychain.

```sh
bash scripts/build-macos.sh app-store
```

The script builds, archives, and exports locally using
`macos/ExportOptions-app-store.plist`. It does not upload or submit. Inspect
the archive in Xcode Organizer, validate it, then upload the validated export
through Organizer or Transporter. Keep the same version/build for this release
across channels; if that build was already uploaded, follow the repository's
monotonic release rules before another upload.

A Mac-specific English listing draft and exact candidate feature profile are
in `docs/mac-app-store/`. Two original-content renderer captures are prepared
under `artifacts/macos-acceptance/screenshots/store-en-US-*.jpg` at 1280×800,
without alpha channels, matching [Apple’s Mac screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).
Other listing languages can be adapted from `docs/app-store/metadata/` after
removing iPhone/iPad-only claims. Add an editor screenshot if desired. Verify
their text and layout at compact and large windows, enlarged text, light/dark
themes and RTL. Existing iOS screenshots are not macOS submission assets.
Use the existing support and privacy URLs on `freevia.org/singbook/`.

Review App Privacy answers for this macOS binary. The bundled app manifest
declares search history and optional account-linked library content for app
functionality, no tracking, and the existing required-reason file timestamp
use. Inspect all bundled plugin manifests with `scripts/inspect-macos.py`.
The manifest does not replace App Store Connect's privacy questionnaire.
Describe Google login as optional access to the user's own Drive library in
review notes; verify the current App Review login-services rule applies to
this use. Complete age rating, encryption, territories, rights and review
contact fields using the owner's existing submission information.

## Direct download

Install the owner's **Developer ID Application** certificate with its private
key and a matching profile for the Keychain capability. Select an appropriate
local signing configuration and run:

```sh
bash scripts/build-macos.sh developer-id
```

The export uses `macos/ExportOptions-developer-id.plist`. If the owner is already
signed into Xcode, notarization can reuse that account without creating an
extra API key or app-specific password. Preserve the verified archive and work
on a clone:

```sh
cp -cR path/to/Singbook.xcarchive path/to/Singbook-developer-id.xcarchive
xcodebuild -exportArchive -archivePath path/to/Singbook-developer-id.xcarchive \
  -exportOptionsPlist macos/ExportOptions-notarize.plist \
  -exportPath path/to/notarization-upload -allowProvisioningUpdates
xcodebuild -exportNotarizedApp -archivePath path/to/Singbook-developer-id.xcarchive \
  -exportPath path/to/notarized-export
```

The second command uploads to Apple's notary service. The final command may
report that Apple is still processing; retry that final export after processing
finishes, keeping the same archive and release number. Verify the exported
app's stapled ticket and Gatekeeper assessment, then create the final ZIP.
This follows [Apple's Xcode notarization workflow](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

Alternatively, verify the Developer ID export and notarize it using an existing
Keychain credential profile:

```sh
codesign --verify --deep --strict path/to/export/Singbook.app
ditto -c -k --sequesterRsrc --keepParent path/to/export/Singbook.app Singbook-submit.zip
xcrun notarytool submit Singbook-submit.zip --keychain-profile YOUR_PROFILE --wait
xcrun stapler staple path/to/export/Singbook.app
xcrun stapler validate path/to/export/Singbook.app
spctl --assess --type execute --verbose path/to/export/Singbook.app
ditto -c -k --sequesterRsrc --keepParent path/to/export/Singbook.app Singbook.zip
shasum -a 256 Singbook.zip
```

Preserve the notarization record, final ZIP/hash and exact source revision.
Download the resulting artifact on a clean Mac and verify Gatekeeper launch,
file import/export, printing and offline library persistence before publishing
the download link. A development-signed local app does not pass this gate.

References: [Flutter macOS release](https://docs.flutter.dev/deployment/macos),
[sandbox and hardened runtime](https://docs.flutter.dev/platform-integration/macos/building),
[Google sign-in macOS configuration](https://pub.dev/packages/google_sign_in_ios).
