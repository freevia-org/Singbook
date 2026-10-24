#!/usr/bin/env python3
"""Check native/Dart Google identifiers without printing local values."""
import argparse
import json
from pathlib import Path
import re


def validate(root: Path, require_google: bool = False) -> bool:
    path = root / 'config/local.defines.json'
    defines = json.loads(path.read_text()) if path.exists() else {}
    if not isinstance(defines, dict):
        raise ValueError('iOS defines must be a JSON object.')
    client = defines.get('VERSE_GOOGLE_IOS_CLIENT_ID', '')
    if not client:
        if require_google:
            raise ValueError('iOS distribution requires Google sync configuration. See docs/ios-sync.md.')
        return False
    if not isinstance(client, str) or not re.fullmatch(r'[A-Za-z0-9_-]+\.apps\.googleusercontent\.com', client):
        raise ValueError('Invalid iOS Google client identifier.')
    settings = {}
    secrets = root / 'ios/Flutter/Secrets.xcconfig'
    if secrets.exists():
        for line in secrets.read_text().splitlines():
            match = re.fullmatch(r'\s*(GID_CLIENT_ID|GID_REVERSED_CLIENT_ID)\s*=\s*(\S+)\s*', line)
            if match:
                if match[1] in settings:
                    raise ValueError('Duplicate iOS Google configuration setting.')
                settings[match[1]] = match[2]
    if settings.get('GID_CLIENT_ID') != client or settings.get('GID_REVERSED_CLIENT_ID') != '.'.join(reversed(client.split('.'))):
        raise ValueError('Native and Dart iOS Google identifiers must match. See docs/ios-sync.md.')
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--require-google', action='store_true')
    args = parser.parse_args()
    try:
        configured = validate(Path(__file__).resolve().parent.parent, args.require_google)
    except (ValueError, OSError):
        raise SystemExit('iOS Google sync configuration is missing, malformed or inconsistent. See docs/ios-sync.md.')
    print('iOS Google sync configuration aligned.' if configured else 'Google sync is not configured for this development build.')
