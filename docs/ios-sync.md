# Google Drive and iCloud sync on iOS

Google Drive and iCloud are separate sync destinations. Google uses the same
Google account and app-folder protocol as Android. iCloud uses the device's
Apple Account and the private CloudKit database shared with Singbook on macOS.
Choose the service explicitly in Settings. Connecting can transfer library
content; signing out must preserve the local library. Switching services must
keep their account baselines separate.

## Google configuration

Create an **iOS** OAuth client for bundle ID `org.freevia.singbook` in the same
Google Cloud project as Android, with Google Drive API enabled. An Android or
Web client ID cannot replace an iOS client. No client secret belongs in the app.

Set `VERSE_GOOGLE_IOS_CLIENT_ID` in ignored `config/local.defines.json`. Set
`GID_CLIENT_ID` to exactly the same value in ignored
`ios/Flutter/Secrets.xcconfig`, and set `GID_REVERSED_CLIENT_ID` to the
reversed dot-separated client ID. Example using a public fixture identifier:

```text
GID_CLIENT_ID = 123-example.apps.googleusercontent.com
GID_REVERSED_CLIENT_ID = com.googleusercontent.apps.123-example
```

Run `python3 scripts/check-ios-sync-config.py --require-google` to check
alignment without printing configuration values. Official IPA builds run this
check; development builds can omit Google configuration. Existing Google
app-data and per-file consent scopes remain unchanged.

## Apple configuration

The Runner entitlements declare CloudKit container
`iCloud.org.freevia.singbook`. The Apple Developer account must register this
container and associate it with the iOS App ID. Regenerate provisioning profiles
with iCloud enabled; an older profile does not gain the capability merely
because the source entitlements changed. The macOS app must use this same
container to share data. Sign in with Apple is not required for CloudKit access.

The shared backend defines the CloudKit record schema and production deployment
requirements. Deploy that reviewed schema before distributing a production
build. Account unavailability, network errors or incomplete listings must produce
an error rather than an empty cloud library. Cross-account changes and stale
record writes must be rejected, preserving local data and conflict copies.

## Validation still required

Configuration checks and simulated channel responses do not prove live Google
or iCloud sync. Validate each service using a disposable library and intended
account: connect, upload, second-device download, concurrent edit/conflict,
remote deletion, offline retry, sign-out and account switching. Verify iPhone
and iPad layout and both Apple development and production environments. Do not
use a personal library for destructive test cases.

References: [Google iOS setup](https://developers.google.com/identity/sign-in/ios/start-integrating),
[Apple iCloud capabilities](https://developer.apple.com/documentation/xcode/configuring-icloud-services),
[CloudKit conditional writes](https://developer.apple.com/documentation/cloudkit/ckmodifyrecordsoperation/savepolicy).
