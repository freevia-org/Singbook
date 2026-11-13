#!/usr/bin/env python3
"""Write a copy of a local defines file that is safe to compile into a desktop app.

Desktop OAuth clients are public clients: the optional client secret in the
ignored local defines must never be compiled into an app or archive. Prints
only the path of the owner-readable temporary copy; the caller deletes it.
"""
import json
import sys
import tempfile

if len(sys.argv) != 2:
    raise SystemExit('Usage: sanitize-defines.py <defines.json>')
with open(sys.argv[1], encoding='utf-8') as source:
    defines = json.load(source)
if not isinstance(defines, dict):
    raise SystemExit('Local defines must be a JSON object.')
defines.pop('SINGBOOK_GOOGLE_DESKTOP_CLIENT_SECRET', None)
with tempfile.NamedTemporaryFile('w', encoding='utf-8', suffix='.json', delete=False) as output:
    json.dump(defines, output, ensure_ascii=False)
    print(output.name)
