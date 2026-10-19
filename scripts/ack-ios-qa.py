#!/usr/bin/env python3
"""Acknowledge an observed native UI result for the opt-in app workflow test.

Run only after the operator has verified the requested sheet was dismissed,
the local backup saved, or the intended backup selected. This coordinates the
test; it does not operate native UI or establish that an action succeeded.
"""
import argparse
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--device', required=True, help='Dedicated test simulator UUID')
parser.add_argument('--log', required=True, type=Path)
parser.add_argument('--stage', required=True)
args = parser.parse_args()
markers = re.findall(r'SINGBOOK_APP_UI_WAIT:(\d+):([\w-]+):([^\r\n]+)',
                     args.log.read_text())
if not markers or markers[-1][1] != args.stage:
    parser.error('The latest native UI request does not match --stage')
session, stage, reported_path = markers[-1]
result = subprocess.run(
    ['xcrun', 'simctl', 'get_app_container', args.device,
     'org.freevia.singbook', 'data'], capture_output=True, text=True,
    check=True, timeout=30,
)
expected = (Path(result.stdout.strip()) / 'Library' / 'Application Support' /
            'singbook-app-qa' / session / f'{stage}.ack').resolve()
if Path(reported_path).resolve() != expected:
    parser.error('The acknowledgement path is not inside the expected test app directory')
if not expected.parent.is_dir():
    parser.error('The test acknowledgement directory no longer exists')
expected.touch(exist_ok=False)
print(f'Acknowledged {stage} for test session {session}')
