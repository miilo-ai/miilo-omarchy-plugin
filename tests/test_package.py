import json
from pathlib import Path
import shutil
import tempfile
import unittest
from tools import check as checker

ROOT = Path(__file__).resolve().parents[1]


class PackageSafety(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for item in ['manifest.json', 'sources.lock.json', 'LICENSE']:
            shutil.copy2(ROOT / item, self.root / item)
        for directory in ['ui', 'vendor', 'assets']:
            shutil.copytree(ROOT / directory, self.root / directory)

    def change_manifest(self, mutate):
        p = self.root / 'manifest.json'
        value = json.loads(p.read_text())
        mutate(value)
        p.write_text(json.dumps(value))

    def test_entry_cannot_escape_repository(self):
        self.change_manifest(lambda m: m['entryPoints'].update(barWidget='../secret.qml'))
        with self.assertRaisesRegex(ValueError, 'Unsafe'):
            checker.check(self.root)

    def test_missing_entry_fails(self):
        self.change_manifest(lambda m: m['entryPoints'].update(barWidget='Missing.qml'))
        with self.assertRaisesRegex(ValueError, 'Missing file'):
            checker.check(self.root)

    def test_symlink_dependency_fails(self):
        (self.root / 'vendor/secret').symlink_to('/tmp')
        with self.assertRaisesRegex(ValueError, 'Symlink'):
            checker.check(self.root)

    def test_unreviewed_vendor_drift_fails(self):
        with (self.root / 'vendor/owl/OwlWidget.qml').open('a') as file:
            file.write('\n// unexpected edit\n')
        with self.assertRaisesRegex(ValueError, 'Unreviewed source drift'):
            checker.check(self.root)

    def test_missing_license_fails(self):
        (self.root / 'vendor/owl/LICENSE').unlink()
        with self.assertRaisesRegex(ValueError, 'Missing file'):
            checker.check(self.root)

    def test_untracked_runtime_file_fails(self):
        (self.root / 'vendor/Hidden.qml').write_text('import QtQuick\nItem {}\n')
        with self.assertRaisesRegex(ValueError, 'Unpinned runtime asset'):
            checker.check(self.root)
