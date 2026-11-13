#!/usr/bin/env bash
# Smoke-check the packaged Linux artifacts themselves, not the build tree.
# Usage: scripts/smoke-linux-packages.sh [packages-dir]
# Requires exactly one .deb and one .AppImage in the directory, checks the
# .deb payload, then launches both packaged copies headlessly (xvfb-run) in
# throwaway data directories. A launch passes when the app is still running
# after the timeout or has exited cleanly. Nothing is installed or published.
set -euo pipefail

packages="${1:-build/linux-packages}"
launch_seconds="${SINGBOOK_SMOKE_SECONDS:-30}"
shopt -s nullglob
debs=("$packages"/*.deb)
appimages=("$packages"/*.AppImage)
if [[ ${#debs[@]} -ne 1 || ${#appimages[@]} -ne 1 ]]; then
  echo "Expected one .deb and one AppImage in $packages; found ${#debs[@]} and ${#appimages[@]}." >&2
  exit 1
fi
deb="${debs[0]}"
appimage="${appimages[0]}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Capture the listing first: a grep that exits early would otherwise break the
# pipe under pipefail. Field 6 of each `dpkg-deb --contents` line is the member
# path; each required payload file is checked on its own, as an exact match.
contents="$(dpkg-deb --contents "$deb" | awk '{print $6}')"
for required in opt/singbook/singbook opt/singbook/lib/libapp.so \
    usr/share/applications/org.freevia.singbook.desktop; do
  if ! grep -qxF "./$required" <<<"$contents"; then
    echo "Packaged .deb is missing $required" >&2
    exit 1
  fi
done

launch() {
  local label="$1"
  shift
  local profile="$work/profile-$label"
  mkdir -p "$profile/data" "$profile/config" "$profile/cache"
  local status=0
  XDG_DATA_HOME="$profile/data" XDG_CONFIG_HOME="$profile/config" \
    XDG_CACHE_HOME="$profile/cache" \
    timeout --kill-after=10 "$launch_seconds" xvfb-run -a "$@" || status=$?
  if [[ $status -ne 0 && $status -ne 124 ]]; then
    echo "Packaged $label failed to start (exit $status)." >&2
    exit 1
  fi
  echo "Packaged $label launched."
}

dpkg-deb --extract "$deb" "$work/deb"
launch deb "$work/deb/opt/singbook/singbook"

# Artifact transfers do not preserve the executable bit.
cp -- "$appimage" "$work/Singbook.AppImage"
chmod +x "$work/Singbook.AppImage"
launch appimage "$work/Singbook.AppImage" --appimage-extract-and-run
