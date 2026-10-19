#!/usr/bin/env python3
"""Validate offline App Store materials; does not sign, upload or certify review."""
import hashlib
import json
from pathlib import Path
import plistlib
import re
import struct

root = Path(__file__).resolve().parent.parent
package = root / 'docs/app-store'
submission = json.loads((package / 'submission.json').read_text())
version = re.search(r'^version:\s*(\S+)', (root / 'pubspec.yaml').read_text(), re.M).group(1)
assert version == f"{submission['version']}+{submission['build']}", 'Metadata version drift'
limits = {'name': 30, 'subtitle': 30, 'promotional_text': 170, 'description': 4000}
for locale in (package / 'metadata').iterdir():
    if not locale.is_dir():
        continue
    for field, limit in limits.items():
        text = (locale / f'{field}.txt').read_text().strip()
        assert text and len(text) <= limit, f'{locale.name}/{field}: exceeds {limit}'
        assert '[OWNER' not in text, f'{field}: unresolved public placeholder'
    keywords = (locale / 'keywords.txt').read_text().strip()
    assert 0 < len(keywords.encode()) <= 100, 'Keywords exceed 100 UTF-8 bytes'
    assert all(len(word) > 2 for word in keywords.split(',')), 'Keyword too short'
assert submission['screenshots'], 'No screenshots prepared'
counts = {}
for shot in submission['screenshots']:
    file = package / shot['file']
    data = file.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', f'{file}: not PNG'
    width, height, depth, color = struct.unpack('>IIBB', data[16:26])
    assert [width, height] == shot['pixels'], f'{file}: wrong dimensions'
    allowed = {'iphone-large': [(1320, 2868), (1290, 2796), (1260, 2736)],
               'ipad-13': [(2048, 2732), (2064, 2752)]}
    assert (width, height) in allowed[shot['display']], f'{file}: unsupported size'
    assert depth == 8 and color == 2, f'{file}: must be 8-bit RGB without alpha'
    assert hashlib.sha256(data).hexdigest() == shot['sha256'], f'{file}: hash changed'
    counts[shot['display']] = counts.get(shot['display'], 0) + 1
for group in ('iphone-large', 'ipad-13'):
    assert 1 <= counts.get(group, 0) <= 10, f'{group}: requires 1–10 screenshots'
info = plistlib.loads((root / 'ios/Runner/Info.plist').read_bytes())
assert info['ITSAppUsesNonExemptEncryption'] is False
assert 'NSAppTransportSecurity' not in info, 'Review transport exceptions'
print(f'Offline materials valid: {version}; screenshot sets {counts}.')
print('Not upload-ready: owner fields, provider authorization/privacy publication, account/signing and Apple validation remain pending.')
