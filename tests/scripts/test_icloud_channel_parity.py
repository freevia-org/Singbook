"""The iOS and macOS CloudKit bridges are maintained as two copies.

Until they share one source file, they must stay identical apart from the
Flutter framework import, so a fix applied to one platform cannot be missed
on the other.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
IMPORTS = {'import Flutter', 'import FlutterMacOS'}


def normalized(relative):
    lines = (ROOT / relative).read_text(encoding='utf-8').splitlines()
    return ['import <Flutter>' if line.strip() in IMPORTS else line for line in lines]


class ICloudChannelParityTest(unittest.TestCase):
    def test_copies_differ_only_by_flutter_import(self):
        ios = normalized('ios/Runner/ICloudSyncChannel.swift')
        macos = normalized('macos/Runner/ICloudSyncChannel.swift')
        self.assertEqual(ios.count('import <Flutter>'), 1)
        self.assertEqual(macos.count('import <Flutter>'), 1)
        self.assertEqual(ios, macos)


if __name__ == '__main__':
    unittest.main()
