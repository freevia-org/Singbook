#!/usr/bin/env python3
"""Inspect a macOS bundle's identity, sandbox, architecture and privacy resources."""
import argparse
import json
import plistlib
import re
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('app', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
contents = args.app / 'Contents'
info = plistlib.loads((contents / 'Info.plist').read_bytes())
version = re.search(r'^version: (\S+)\+(\d+)$', (root / 'pubspec.yaml').read_text(), re.M)
assert info['CFBundleIdentifier'] == 'org.freevia.singbook', 'Unexpected bundle ID'
assert (info['CFBundleShortVersionString'], info['CFBundleVersion']) == version.groups(), 'Version drift'
assert info['LSApplicationCategoryType'] == 'public.app-category.music'
expected = plistlib.loads((root / 'macos/Runner/PrivacyInfo.xcprivacy').read_bytes())
declared = {entry['NSPrivacyCollectedDataType']: entry
            for entry in expected.get('NSPrivacyCollectedDataTypes', [])}
for data_type in ['OtherUserContent', 'SearchHistory']:
    entry = declared.get('NSPrivacyCollectedDataType' + data_type, {})
    assert entry.get('NSPrivacyCollectedDataTypeLinked') is True, (
        f'Missing linked sync/search disclosure: {data_type}')
    assert entry.get('NSPrivacyCollectedDataTypeTracking') is False, (
        f'Unexpected tracking disclosure: {data_type}')
    assert entry.get('NSPrivacyCollectedDataTypePurposes') == [
        'NSPrivacyCollectedDataTypePurposeAppFunctionality'
    ], f'Unexpected data purpose: {data_type}'
manifests = list(contents.rglob('PrivacyInfo.xcprivacy'))
app_manifest = contents / 'Resources/PrivacyInfo.xcprivacy'
assert app_manifest.is_file(), 'Missing app privacy manifest at Contents/Resources'
assert plistlib.loads(app_manifest.read_bytes()) == expected, 'App privacy manifest differs from source'
for path in manifests:
    for entry in plistlib.loads(path.read_bytes()).get('NSPrivacyAccessedAPITypes', []):
        assert entry.get('NSPrivacyAccessedAPITypeReasons'), f'Missing required reason: {path.name}'
signed = subprocess.run(['codesign', '-d', '--entitlements', ':-', str(args.app)], capture_output=True)
entitlements = plistlib.loads(signed.stdout) if signed.returncode == 0 and signed.stdout else {}
for key in ['app-sandbox', 'network.client', 'files.user-selected.read-write', 'print']:
    assert entitlements.get('com.apple.security.' + key) is True, f'Missing entitlement: {key}'
if 'Debug' not in str(args.app):
    assert not entitlements.get('com.apple.security.cs.allow-jit'), 'Release has debug JIT entitlement'
architectures = subprocess.check_output(['lipo', '-archs', str(contents / 'MacOS' / info['CFBundleExecutable'])], text=True).strip()
assert set(architectures.split()) == {'arm64', 'x86_64'}, 'Expected universal Intel/Apple Silicon app'
print(json.dumps({'bundleIdentifier': info['CFBundleIdentifier'], 'version': version[1], 'build': version[2],
                  'minimumOS': info['LSMinimumSystemVersion'], 'architectures': architectures,
                  'privacyManifestCount': len(manifests), 'sandboxVerified': True}, indent=2))
