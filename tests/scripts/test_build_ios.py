"""Exercise build orchestration with fake tools, without Xcode or Flutter."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class IosBuildOrchestrationTest(unittest.TestCase):
    def run_build(self, mode, fail_dependencies=False, invalid_google=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'scripts').mkdir()
            (root / 'config').mkdir()
            source = Path(__file__).resolve().parents[2]
            client = 'test-ios.apps.googleusercontent.com'
            (root / 'config/local.defines.json').write_text(json.dumps({
                'VERSE_GOOGLE_IOS_CLIENT_ID': client,
            }))
            (root / 'ios/Flutter').mkdir(parents=True)
            native_client = 'mismatch.apps.googleusercontent.com' if invalid_google else client
            (root / 'ios/Flutter/Secrets.xcconfig').write_text(
                f'GID_CLIENT_ID = {native_client}\n'
                f'GID_REVERSED_CLIENT_ID = {".".join(reversed(native_client.split(".")))}\n')
            for script in ('build-ios.sh', 'check-ios-sync-config.py'):
                shutil.copyfile(source / 'scripts' / script, root / 'scripts' / script)
            (root / 'ios/Runner').mkdir()
            shutil.copyfile(source / 'ios/Runner/PrivacyInfo.xcprivacy',
                            root / 'ios/Runner/PrivacyInfo.xcprivacy')
            tools = root / 'bin'
            tools.mkdir()
            for name in ('flutter', 'xcodebuild'):
                tool = tools / name
                tool.write_text(f'#!{sys.executable}\n' + '''import json, os, sys
with open(os.environ['CALL_LOG'], 'a') as log:
    log.write(json.dumps([os.path.basename(sys.argv[0]), *sys.argv[1:]]) + '\\n')
if sys.argv[1:3] == ['pub', 'get'] and os.environ.get('FAIL_DEPENDENCIES'):
    sys.exit(17)
''')
                tool.chmod(0o755)
            log = root / 'calls.jsonl'
            env = {**os.environ, 'PATH': str(tools) + os.pathsep + os.environ['PATH'],
                   'CALL_LOG': str(log), 'FAIL_DEPENDENCIES': '1' if fail_dependencies else ''}
            result = subprocess.run(['bash', str(root / 'scripts/build-ios.sh'), mode],
                                    env=env, capture_output=True, text=True)
            return result, [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []

    def test_all_modes_resolve_once_then_build_without_pub(self):
        for mode, expected in [('simulator', ['ios', '--simulator', '--debug']),
                               ('device', ['ios', '--release', '--no-codesign']),
                               ('archive', ['ipa', '--release', '--no-codesign']),
                               ('ipa', ['ipa', '--release'])]:
            with self.subTest(mode=mode):
                result, calls = self.run_build(mode)
                self.assertEqual(result.returncode, 0, result.stderr)
                flutter = [call[1:] for call in calls if call[0] == 'flutter']
                self.assertEqual(flutter[:2], [['pub', 'get', '--enforce-lockfile'], ['gen-l10n']])
                self.assertEqual(len(flutter), 3)
                self.assertEqual(flutter[2][:1 + len(expected)], ['build', *expected])
                self.assertIn('--no-pub', flutter[2])
                self.assertIn('--dart-define-from-file=config/local.defines.json', flutter[2])
                if mode == 'ipa':
                    self.assertIn('--export-options-plist=ios/ExportOptions.plist', flutter[2])

    def test_mismatched_google_configuration_never_resolves_or_builds(self):
        result, calls = self.run_build('ipa', invalid_google=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(call[0] == 'flutter' for call in calls))
        self.assertIn('configuration is missing, malformed or inconsistent', result.stderr)

    def test_failed_dependency_resolution_never_builds(self):
        result, calls = self.run_build('device', fail_dependencies=True)
        self.assertEqual(result.returncode, 17)
        self.assertFalse(any('build' in call or 'gen-l10n' in call for call in calls))


if __name__ == '__main__':
    unittest.main()
