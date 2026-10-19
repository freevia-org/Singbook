#!/usr/bin/env python3
"""Inspect bundled privacy plists; this is not an App Store compliance check."""
import argparse
import json
import plistlib
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("path", type=Path, help="Runner.app or Runner.xcarchive")
args = parser.parse_args()
app = args.path
if app.suffix == ".xcarchive":
    app = app / "Products/Applications/Runner.app"
info = plistlib.loads((app / "Info.plist").read_bytes())
expected = plistlib.loads(
    (Path(__file__).resolve().parent.parent / "ios/Runner/PrivacyInfo.xcprivacy").read_bytes()
)
actual = plistlib.loads((app / "PrivacyInfo.xcprivacy").read_bytes())
if actual != expected:
    raise SystemExit("Bundled app manifest does not match the reviewed source manifest")
if info["CFBundleIdentifier"] != "org.freevia.singbook":
    raise SystemExit("Unexpected bundle identifier")
manifests = []
for path in sorted(app.rglob("PrivacyInfo.xcprivacy")):
    data = plistlib.loads(path.read_bytes())
    accesses = data.get("NSPrivacyAccessedAPITypes", [])
    for entry in accesses:
        if not entry.get("NSPrivacyAccessedAPITypeReasons"):
            raise SystemExit(f"Missing required reasons in {path}")
    manifests.append({
        "path": str(path.relative_to(app)),
        "tracking": data.get("NSPrivacyTracking"),
        "accessedAPIs": accesses,
        "collectedData": data.get("NSPrivacyCollectedDataTypes", []),
    })
print(json.dumps({
    "bundleIdentifier": info["CFBundleIdentifier"],
    "version": info["CFBundleShortVersionString"],
    "build": info["CFBundleVersion"],
    "minimumOS": info["MinimumOSVersion"],
    "manifestCount": len(manifests),
    "manifests": manifests,
}, indent=2))
