#!/usr/bin/env bash
set -eo pipefail
cd "$(dirname "$0")/.."

mode="${1:-simulator}"
case "$mode" in
  simulator|device|archive|ipa) ;;
  *) echo "Usage: bash scripts/build-ios.sh [simulator|device|archive|ipa]" >&2; exit 2 ;;
esac

if ! command -v flutter >/dev/null; then
  echo "Add Flutter 3.44.8 to PATH. See docs/ios-build.md." >&2
  exit 1
fi
if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Install and select full Xcode. See docs/ios-build.md." >&2
  exit 1
fi

defines=()
if [[ -f config/local.defines.json ]]; then
  defines+=(--dart-define-from-file=config/local.defines.json)
elif [[ "$mode" == ipa ]]; then
  echo "IPA builds require config/local.defines.json; see config/defines.example.json." >&2
  exit 1
else
  echo "No local defines: Genius and Google sync will be unavailable."
fi

if [[ "$mode" == ipa ]]; then
  python3 - <<'PY'
import json
import plistlib
from pathlib import Path

defines = json.loads(Path('config/local.defines.json').read_text())
ios_id = defines.get('VERSE_GOOGLE_IOS_CLIENT_ID', '')
if isinstance(ios_id, str) and ios_id.endswith('.apps.googleusercontent.com'):
    manifest = plistlib.loads(Path('ios/Runner/PrivacyInfo.xcprivacy').read_bytes())
    content = next((item for item in manifest.get('NSPrivacyCollectedDataTypes', [])
                    if item.get('NSPrivacyCollectedDataType') == 'NSPrivacyCollectedDataTypeOtherUserContent'), None)
    if not content or not content.get('NSPrivacyCollectedDataTypeLinked') or \
            'NSPrivacyCollectedDataTypePurposeAppFunctionality' not in content.get('NSPrivacyCollectedDataTypePurposes', []):
        raise SystemExit('Drive is configured: review and declare account-linked Other User Content for App Functionality in Runner privacy manifest before IPA export. See docs/ios-app-privacy.md.')
PY
fi

flutter pub get --enforce-lockfile
flutter gen-l10n
case "$mode" in
  simulator) flutter build ios --simulator --debug --no-pub "${defines[@]}" ;;
  device) flutter build ios --release --no-codesign --no-pub "${defines[@]}" ;;
  archive) flutter build ipa --release --no-codesign --no-pub "${defines[@]}" ;;
  ipa) flutter build ipa --release --no-pub --export-options-plist=ios/ExportOptions.plist "${defines[@]}" ;;
esac
