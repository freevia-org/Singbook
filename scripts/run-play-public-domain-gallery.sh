#!/usr/bin/env bash
set -euo pipefail

# Called only on a fresh GitHub-hosted Android emulator from the manual action.
out=artifacts/play-gallery-026
mkdir -p "$out"
test "$(git rev-parse HEAD)" = '1120fc1e0faf3d0e59435390d9fb1fdaa13174ac'

# Verify the published APK as provenance, while capturing via the identical
# tagged source plus a test-only, isolated public-domain SQLite library.
apk="$out/singbook-0.2.26+40-release.apk"
curl --fail --location --silent --show-error \
  'https://github.com/freevia-org/Singbook/releases/download/v0.2.26/singbook-0.2.26+40-release.apk' \
  --output "$apk"
echo '0cf29a6ace57daf2e80bdf3380f8887e16fdc7952dad3cffe5d92641de56e56b  '"$apk" | sha256sum --check --status

adb devices
adb shell wm size 1080x1920
adb shell wm density 420
export SINGBOOK_SCREENSHOT_DIR="$out"
# v0.2.26 explicitly provides this Debug-only fixture flag. It excludes the
# duplicate-namespace cronet-shared artifact from the screenshot test build;
# ordinary Debug and all Release builds remain unchanged.
grep -q 'val fixtureE2e = providers.gradleProperty("singbookFixtureE2e")' android/app/build.gradle.kts
export ORG_GRADLE_PROJECT_singbookFixtureE2e=true
flutter drive --no-pub -d emulator-5554 \
  --driver=test_driver/singbook_journey_device_test.dart \
  --target=integration_test/play_public_domain_gallery_device_test.dart \
  --dart-define=SINGBOOK_STORE_CAPTURE=true \
  2>&1 | tee "$out/flutter-drive.log"

python3 - "$out" <<'PY'
import hashlib, pathlib, struct, sys
out = pathlib.Path(sys.argv[1])
images = sorted(out.glob('0*-device.png'))
assert len(images) == 5, f'Expected five native screenshots, got {len(images)}'
with (out / 'PROVENANCE.txt').open('w', encoding='utf-8') as f:
    f.write('Singbook 0.2.26+40 Play gallery raw evidence\n')
    f.write('Source tag v0.2.26 commit 1120fc1e0faf3d0e59435390d9fb1fdaa13174ac\n')
    f.write('UI rendered by Flutter integration test from release tag, not by the signed APK.\n')
    f.write('Signed GitHub APK verified SHA-256 0cf29a6ace57daf2e80bdf3380f8887e16fdc7952dad3cffe5d92641de56e56b\n')
    f.write('Android emulator API 36, 1080x1920, fresh instance. No phone, account, or network source used.\n')
    f.write('Public-domain lyric source details: capture/docs/play-store/public-domain-gallery.md\n')
    for p in images:
        b = p.read_bytes()
        assert b[:8] == b'\x89PNG\r\n\x1a\n'
        width, height = struct.unpack('>II', b[16:24])
        assert (width, height) == (1080, 1920), (p.name, width, height)
        f.write(f'{p.name} {width}x{height} sha256 {hashlib.sha256(b).hexdigest()}\n')
PY

# Release APK is verified but not included in the screenshot artifact.
rm "$apk"
