# Build Singbook on macOS

Use Flutter 3.44.8 / Dart 3.12 and full Xcode. Runner targets iOS 15 or later
to match the minimum deployment target accepted by Xcode 27.1 (the resolved
file picker also requires at least iOS 14). Command Line Tools alone cannot
build an iOS app. This project already integrates Swift Package Manager;
let Flutter resolve plugins before introducing a Podfile. Install CocoaPods
if Flutter reports that a dependency needs its fallback integration.

Official setup: https://docs.flutter.dev/platform-integration/ios/setup

## Prepare the Mac

Install Xcode from the Mac App Store, launch it, and finish its component setup.
Then select it and install the iOS platform support:

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcodebuild -downloadPlatform iOS
```

Add the Flutter SDK's `bin` directory to your shell's PATH. On this Mac an SDK
checkout exists at `/Users/tony/development/flutter`:

```sh
export PATH="/Users/tony/development/flutter/bin:$PATH"
flutter --version
flutter doctor -v
flutter precache --ios
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

## Local builds

```sh
bash scripts/build-ios.sh simulator
# Unsigned device compilation; cannot be installed as-is:
bash scripts/build-ios.sh device
```

The simulator output is `build/ios/iphonesimulator/Runner.app`.
To launch interactively, start an iOS simulator through Xcode, run
`flutter devices`, then `flutter run -d <simulator-id>`.
Pass `--dart-define-from-file=config/local.defines.json` to `flutter run`
when using local configuration.

## Configuration and distribution

Copy `config/defines.example.json` to the ignored `config/local.defines.json`
and fill in the public build identifiers and Genius client access token.
For Google sync, follow [OAuth setup](google-oauth-setup.md): also create the
ignored `ios/Flutter/Secrets.xcconfig` with `GID_CLIENT_ID` matching the Dart
iOS client ID and `GID_REVERSED_CLIENT_ID` matching its reversed URL scheme.
Offline library features can be built without this configuration.

Open `ios/Runner.xcworkspace` in Xcode after Flutter resolves dependencies.
Select Runner's Signing & Capabilities, choose your Apple development team,
and retain bundle ID `org.freevia.singbook`. Team selection and provisioning
require the owner's Apple account. For a signed archive and IPA:

```sh
bash scripts/build-ios.sh ipa
```

Archives go to `build/ios/archive`, exported IPAs to `build/ios/ipa`.
Before distribution, audit app and plugin privacy manifests and required-reason
APIs (see the [TestFlight privacy review](ios-testflight.md)), verify signing and App
Store Connect configuration, and test Google sign-in/sync, file import/export,
printing, and phone/tablet layouts on iOS. See [Google and iCloud sync](ios-sync.md)
for both services and their configuration and validation requirements.
Preparation does not establish App Store readiness or device compatibility.

## Local validation — 2026-10-18

Starting from public commit `7253b4f1cfcad3ed56c187eefc1e4890c930920f`,
using Flutter 3.44.8 / Dart 3.12.2 and Xcode 27.1 (27A9275):

- Simulator debug build passed through `scripts/build-ios.sh simulator`.
- Unsigned device release build passed through `scripts/build-ios.sh device`.
- Installed and launched the simulator app on a dedicated `Singbook iPhone Duo`
  simulator running iOS 27.1. Visually checked the home screen on display 1;
  this dual-display runtime defaults screenshots to the unused display 3.
  Local screenshot and build logs are in ignored `artifacts/ios-preparation/`.
- Runner deployment target was raised from iOS 13 to 15 after Xcode rejected
  the old target. The built simulator bundle reports iOS 15.0 and bundle ID
  `org.freevia.singbook`.
- Swift Package Manager resolved native dependencies without CocoaPods. Both
  Xcode workspace resolution files are retained to record the resolved versions.
- Earlier Dart analysis passed. The existing full test suite had 1,255 passes
  and four golden image failures in `test/ui/chord_lyrics_line_test.dart`;
  a focused rerun confirmed pixel differences. On 2026-10-19, reviewed macOS
  baselines resolved these host rasterization differences; all 12 focused tests
  passed without updating goldens during verification.

These builds omit local API/OAuth configuration. No signed IPA, physical-device
installation, or Google sign-in/sync validation has been performed.

For signing configuration, archive inspection, privacy findings, and the
remaining upload requirements, see [TestFlight preparation](ios-testflight.md).
