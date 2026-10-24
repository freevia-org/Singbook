#!/usr/bin/env python3
"""Create the ignored macOS OAuth xcconfig from local public client IDs."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
defines_path = root / 'config/local.defines.json'
if not defines_path.exists():
    raise SystemExit('Missing config/local.defines.json; macOS OAuth remains disabled.')
defines = json.loads(defines_path.read_text())
client = defines.get('VERSE_GOOGLE_MACOS_CLIENT_ID') or defines.get('VERSE_GOOGLE_IOS_CLIENT_ID', '')
if not isinstance(client, str) or not re.fullmatch(r'[A-Za-z0-9_-]+\.apps\.googleusercontent\.com', client):
    raise SystemExit('No valid macOS or iOS OAuth client ID; macOS OAuth remains disabled.')

destination = root / 'macos/Runner/Configs/Secrets.xcconfig'
if destination.exists():
    raise SystemExit('macOS Secrets.xcconfig already exists; refusing to overwrite it.')
reversed_id = '.'.join(reversed(client.split('.')))
destination.write_text(
    '// Generated locally; ignored by Git. Do not commit.\n'
    f'GID_CLIENT_ID = {client}\n'
    f'GID_REVERSED_CLIENT_ID = {reversed_id}\n'
)
print('Created ignored macOS OAuth configuration.')
