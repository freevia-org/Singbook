#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

mode="${1:-release}"
if [[ "$mode" != release ]]; then
  echo "Usage: scripts/build-linux.sh [release]" >&2
  exit 2
fi
command -v flutter >/dev/null || { echo 'Add Flutter 3.44.8 to PATH.' >&2; exit 1; }

defines=(--no-pub)
sanitized_defines_file=''
cleanup_sanitized_defines() {
  if [[ -n "$sanitized_defines_file" && -f "$sanitized_defines_file" ]]; then
    rm -f -- "$sanitized_defines_file"
  fi
}
trap cleanup_sanitized_defines EXIT

if [[ -f config/local.defines.json ]]; then
  # Desktop OAuth clients are public clients; never compile the optional client
  # secret from ignored local defines into an app or package.
  sanitized_defines_file="$(python3 scripts/sanitize-defines.py config/local.defines.json)"
  defines+=(--dart-define-from-file="$sanitized_defines_file")
else
  echo 'No local defines: Google sync and Genius are unavailable.'
fi

if [[ -n "${SINGBOOK_GOOGLE_DESKTOP_CLIENT_ID:-}" ]]; then
  defines+=(--dart-define=SINGBOOK_GOOGLE_DESKTOP_CLIENT_ID="$SINGBOOK_GOOGLE_DESKTOP_CLIENT_ID")
fi

flutter build linux --release "${defines[@]}"
