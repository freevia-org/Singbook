#!/usr/bin/env bash
# Build locally or archive/export using the owner's ignored signing settings.
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:-release}"
case "$mode" in
  release|debug|archive|app-store|developer-id) ;;
  *) echo "Usage: bash scripts/build-macos.sh [release|debug|archive|app-store|developer-id]" >&2; exit 2 ;;
esac
command -v flutter >/dev/null || { echo 'Add Flutter 3.44.8 to PATH.' >&2; exit 1; }
xcodebuild -version >/dev/null
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
revision="$(git rev-parse HEAD)"
evidence="artifacts/macos/${stamp}-${revision:0:8}-$$"
mkdir -p "$evidence"
git status --porcelain > "$evidence/source-status.txt"
git diff --binary HEAD > "$evidence/source.patch"
git ls-files --others --exclude-standard > "$evidence/source-untracked.txt"
printf '%s\n' "$revision" > "$evidence/source-commit.txt"
flutter --version > "$evidence/flutter-version.txt"
xcodebuild -version > "$evidence/xcode-version.txt"
defines=(--no-pub)
if [[ -f config/local.defines.json ]]; then
  defines+=(--dart-define-from-file=config/local.defines.json)
else
  echo 'No local defines: Google sync and Genius are unavailable.'
fi
if [[ "$mode" == app-store || "$mode" == developer-id || "$mode" == archive ]]; then
  [[ -f macos/Runner/Configs/Signing.xcconfig ]] || {
    echo 'Configure macos/Runner/Configs/Signing.xcconfig before signed archives.' >&2; exit 1;
  }
fi
# Never print configuration contents or credentials into build evidence.
python3 scripts/check-macos-config.py
flutter pub get --enforce-lockfile
flutter gen-l10n
configuration=release
[[ "$mode" != debug ]] || configuration=debug
flutter build macos "--$configuration" --config-only "${defines[@]}" 2>&1 | tee "$evidence/configure.log"
product_configuration=Release
[[ "$configuration" != debug ]] || product_configuration=Debug
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration "$product_configuration" -destination 'platform=macOS' \
  -derivedDataPath build/macos build \
  2>&1 | tee "$evidence/build.log"
app="build/macos/Build/Products/$product_configuration/Singbook.app"
python3 scripts/inspect-macos.py "$app" > "$evidence/bundle-report.json"
ditto "$app" "$evidence/Singbook.app"
if [[ "$mode" == archive || "$mode" == app-store || "$mode" == developer-id ]]; then
  xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
    -configuration Release -destination 'generic/platform=macOS' \
    -derivedDataPath build/macos -archivePath "$PWD/$evidence/Singbook.xcarchive" archive \
    2>&1 | tee "$evidence/archive.log"
fi
if [[ "$mode" == app-store || "$mode" == developer-id ]]; then
  xcodebuild -exportArchive -archivePath "$PWD/$evidence/Singbook.xcarchive" \
    -exportOptionsPlist "macos/ExportOptions-$mode.plist" \
    -exportPath "$PWD/$evidence/export" 2>&1 | tee "$evidence/export.log"
fi
ditto -c -k --sequesterRsrc --keepParent "$evidence/Singbook.app" "$evidence/Singbook-preview.zip"
shasum -a 256 "$evidence/Singbook-preview.zip" > "$evidence/SHA256SUMS"
echo "Build evidence: $evidence"
echo 'Preview ZIP is local validation output; use signed export and notarization for publication.'
