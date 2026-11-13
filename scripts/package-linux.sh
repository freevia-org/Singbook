#!/usr/bin/env bash
# Package build/linux/x64/release/bundle as an AppImage and a .deb.
# Usage: scripts/package-linux.sh [output-dir]   (run `flutter build linux --release` first)
# Needs: dpkg-deb, ImageMagick (convert) and, for the AppImage, appimagetool
# and the AppImage type2 runtime. Both are downloaded from pinned upstream
# releases and verified against the SHA-256 digests below before use; set
# APPIMAGETOOL=/path and/or APPIMAGE_RUNTIME=/path to supply local copies
# instead (those are used as given). Nothing is published.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$root/build/linux-packages}"
bundle="$root/build/linux/x64/release/bundle"
[[ -x "$bundle/singbook" ]] || { echo "Missing $bundle/singbook; build first." >&2; exit 1; }
canonical_version="$(awk -F': *' '/^version:/ {print $2}' "$root/pubspec.yaml")"
[[ "$canonical_version" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$ ]] || { echo 'Version must be MAJOR.MINOR.PATCH+BUILD.' >&2; exit 1; }
version="${BASH_REMATCH[1]}"
build="${BASH_REMATCH[2]}"
id=org.freevia.singbook
desktop="$root/linux/packaging/$id.desktop"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$out"
convert "$root/assets/branding/singbook-icon.png" -resize 256x256 "$work/icon.png"

# --- .deb: /opt/singbook + /usr/bin/singbook launcher
pkg="$work/deb"
mkdir -p "$pkg/DEBIAN" "$pkg/opt/singbook" "$pkg/usr/bin" \
  "$pkg/usr/share/applications" "$pkg/usr/share/icons/hicolor/256x256/apps"
cp -a "$bundle/." "$pkg/opt/singbook/"
ln -s /opt/singbook/singbook "$pkg/usr/bin/singbook"
cp "$desktop" "$pkg/usr/share/applications/$id.desktop"
cp "$work/icon.png" "$pkg/usr/share/icons/hicolor/256x256/apps/$id.png"
cat > "$pkg/DEBIAN/control" <<CTL
Package: singbook
Version: $version-$build
Architecture: amd64
Maintainer: Freevia <https://freevia.org/singbook/>
Section: sound
Priority: optional
Depends: libgtk-3-0, libc6
Recommends: zenity | kdialog, xdg-utils
Homepage: https://freevia.org/singbook/
Description: Lyrics, chords and songbooks, together offline
 Singbook is a lyrics and chords app with songbooks, setlists, timed lyrics
 and optional Google Drive sync.
CTL
find "$pkg" -type d -exec chmod 755 {} +
dpkg-deb --root-owner-group --build "$pkg" "$out/singbook_${version}-${build}_amd64.deb"

# --- AppImage
app="$work/Singbook.AppDir"
mkdir -p "$app/usr/lib/singbook"
cp -a "$bundle/." "$app/usr/lib/singbook/"
cp "$desktop" "$app/$id.desktop"
sed -i 's|^Exec=.*|Exec=AppRun|' "$app/$id.desktop"
cp "$work/icon.png" "$app/$id.png"
cat > "$app/AppRun" <<'RUN'
#!/bin/sh
here="$(dirname "$(readlink -f "$0")")"
exec "$here/usr/lib/singbook/singbook" "$@"
RUN
chmod +x "$app/AppRun"
# Pinned upstream artifacts. The digests are the SHA-256 values GitHub records
# for these exact release assets (REST API `digest` field). The runtime becomes
# the executable header of the shipped AppImage: without --runtime-file,
# appimagetool would fetch a mutable "continuous" build at packaging time.
appimagetool_url=https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage
appimagetool_sha256=ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
runtime_url=https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64
runtime_sha256=2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d

# Download to a temporary name and only move into place after verification,
# so an unverified file is never executable or reused.
fetch_verified() {
  local url="$1" sha256="$2" destination="$3"
  curl -fsSL --proto '=https' --tlsv1.2 -o "$destination.download" "$url"
  if ! echo "$sha256  $destination.download" | sha256sum --check --status; then
    rm -f -- "$destination.download"
    echo "SHA-256 verification failed for $url" >&2
    exit 1
  fi
  mv -- "$destination.download" "$destination"
}

tool="${APPIMAGETOOL:-}"
if [[ -z "$tool" ]]; then
  tool="$work/appimagetool-x86_64.AppImage"
  fetch_verified "$appimagetool_url" "$appimagetool_sha256" "$tool"
  chmod +x "$tool"
fi
[[ -x "$tool" ]] || { echo "appimagetool is not executable: $tool" >&2; exit 1; }
runtime="${APPIMAGE_RUNTIME:-}"
if [[ -z "$runtime" ]]; then
  runtime="$work/runtime-x86_64"
  fetch_verified "$runtime_url" "$runtime_sha256" "$runtime"
fi
[[ -s "$runtime" ]] || { echo "AppImage runtime is missing: $runtime" >&2; exit 1; }
ARCH=x86_64 "$tool" --appimage-extract-and-run --runtime-file "$runtime" \
  "$app" "$out/Singbook-${version}-${build}-x86_64.AppImage"
ls -l "$out"
