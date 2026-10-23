#!/usr/bin/env python3
"""Validate native/Dart OAuth alignment without exposing configuration values."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
defines_path = root / 'config/local.defines.json'
defines = json.loads(defines_path.read_text()) if defines_path.exists() else {}
client = defines.get('VERSE_GOOGLE_MACOS_CLIENT_ID', '')
if client:
    if not isinstance(client, str) or not re.fullmatch(r'[A-Za-z0-9_-]+\.apps\.googleusercontent\.com', client):
        raise SystemExit('Invalid macOS OAuth client identifier.')
    secrets = root / 'macos/Runner/Configs/Secrets.xcconfig'
    settings = {}
    if secrets.exists():
        for line in secrets.read_text().splitlines():
            match = re.fullmatch(r'\s*(GID_CLIENT_ID|GID_REVERSED_CLIENT_ID)\s*=\s*(\S+)\s*', line)
            if match:
                settings[match[1]] = match[2]
    if settings.get('GID_CLIENT_ID') != client or settings.get('GID_REVERSED_CLIENT_ID') != '.'.join(reversed(client.split('.'))):
        raise SystemExit('macOS OAuth identifiers must match Dart configuration; see docs/macos-publishing.md.')
print('macOS OAuth configuration aligned.' if client else 'macOS OAuth disabled in this build.')
