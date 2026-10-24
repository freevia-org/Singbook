"""No SDK/account dependencies; public fixture identifiers only."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

module_path = Path(__file__).resolve().parents[2] / 'scripts/check-ios-sync-config.py'
spec = importlib.util.spec_from_file_location('ios_sync_config', module_path)
config = importlib.util.module_from_spec(spec)
spec.loader.exec_module(config)


class IOSSyncConfigTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'config').mkdir()
        (self.root / 'ios/Flutter').mkdir(parents=True)

    def write(self, client='123-fixture.apps.googleusercontent.com', native=None):
        (self.root / 'config/local.defines.json').write_text(json.dumps({'VERSE_GOOGLE_IOS_CLIENT_ID': client}))
        if native is not None:
            (self.root / 'ios/Flutter/Secrets.xcconfig').write_text(native)

    def test_missing_allowed_for_development_but_distribution_rejected(self):
        self.assertFalse(config.validate(self.root))
        with self.assertRaises(ValueError):
            config.validate(self.root, require_google=True)

    def test_nonobject_json_rejected(self):
        for value in [[], None, 'text', 42]:
            (self.root / 'config/local.defines.json').write_text(json.dumps(value))
            with self.assertRaises(ValueError):
                config.validate(self.root)

    def test_native_dart_alignment_required(self):
        self.write(native='GID_CLIENT_ID = 123-fixture.apps.googleusercontent.com\nGID_REVERSED_CLIENT_ID = com.googleusercontent.apps.123-fixture\n')
        self.assertTrue(config.validate(self.root, require_google=True))
        self.write(native='GID_CLIENT_ID = 123-other.apps.googleusercontent.com\nGID_REVERSED_CLIENT_ID = com.googleusercontent.apps.123-other\n')
        with self.assertRaises(ValueError):
            config.validate(self.root)

    def test_nonstring_and_invalid_client_rejected(self):
        for client in [123, 'web.example', 'bad value.apps.googleusercontent.com']:
            self.write(client=client)
            with self.assertRaises(ValueError):
                config.validate(self.root)

    def test_missing_native_and_duplicate_native_rejected(self):
        self.write()
        with self.assertRaises(ValueError):
            config.validate(self.root)
        self.write(native='GID_CLIENT_ID = 123-fixture.apps.googleusercontent.com\nGID_CLIENT_ID = 123-fixture.apps.googleusercontent.com\n')
        with self.assertRaises(ValueError):
            config.validate(self.root)


if __name__ == '__main__':
    unittest.main()
