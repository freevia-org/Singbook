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
  sanitized_defines_file="$(python3 - config/local.defines.json <<'PY'
import json
import sys
import tempfile

with open(sys.argv[1], encoding='utf-8') as source:
    defines = json.load(source)
if not isinstance(defines, dict):
    raise SystemExit('Local defines must be a JSON object.')
defines.pop('SINGBOOK_GOOGLE_DESKTOP_CLIENT_SECRET', None)
with tempfile.NamedTemporaryFile('w', encoding='utf-8', suffix='.json', delete=False) as output:
    json.dump(defines, output, ensure_ascii=False)
    print(output.name)
PY
)"
  defines+=(--dart-define-from-file="$sanitized_defines_file")
else
  echo 'No local defines: Google sync and Genius are unavailable.'
fi

if [[ -n "${SINGBOOK_GOOGLE_DESKTOP_CLIENT_ID:-}" ]]; then
  defines+=(--dart-define=SINGBOOK_GOOGLE_DESKTOP_CLIENT_ID="$SINGBOOK_GOOGLE_DESKTOP_CLIENT_ID")
fi

flutter build linux --release "${defines[@]}"
