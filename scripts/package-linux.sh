#!/usr/bin/env bash
# Package build/linux/x64/release/bundle as an AppImage and a .deb.
# Usage: scripts/package-linux.sh [output-dir]   (run `flutter build linux --release` first)
# Needs: dpkg-deb, ImageMagick (convert) and, for the AppImage, appimagetool
# (APPIMAGETOOL=/path or downloaded to the output dir). Nothing is published.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$root/build/linux-packages}"
bundle="$root/build/linux/x64/release/bundle"
[[ -x "$bundle/singbook" ]] || { echo "Missing $bundle/singbook; build first." >&2; exit 1; }
version="$(sed -n 's/^version: *\([0-9.]*\)+.*/\1/p' "$root/pubspec.yaml")"
build="$(sed -n 's/^version: *[0-9.]*+\([0-9]*\).*/\1/p' "$root/pubspec.yaml")"
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
sed -i 's|^Exec=.*|Exec=AppRun %F|' "$app/$id.desktop"
cp "$work/icon.png" "$app/$id.png"
cat > "$app/AppRun" <<'RUN'
#!/bin/sh
here="$(dirname "$(readlink -f "$0")")"
exec "$here/usr/lib/singbook/singbook" "$@"
RUN
chmod +x "$app/AppRun"
tool="${APPIMAGETOOL:-$out/appimagetool-x86_64.AppImage}"
if [[ ! -x "$tool" ]]; then
  curl -fsSL -o "$tool" \
    https://github.com/AppImage/appimagetool/releases/download/1.9.0/appimagetool-x86_64.AppImage
  chmod +x "$tool"
fi
ARCH=x86_64 "$tool" --appimage-extract-and-run "$app" "$out/Singbook-${version}-${build}-x86_64.AppImage"
rm -f "$out/appimagetool-x86_64.AppImage"
ls -l "$out"
