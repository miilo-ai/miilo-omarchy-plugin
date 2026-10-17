"""Exercise real file installation with inert version-only fixture binaries."""
import importlib.util
import json
from pathlib import Path
import tempfile
import types
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('dev_install', ROOT / 'tools/install-dev-plugin.py')
INSTALL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(INSTALL)


class DevInstall(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        target = self.base / 'plugins/io.miilo.bar'
        target.mkdir(parents=True)
        (target / 'manifest.json').write_text(json.dumps({'id': 'io.miilo.bar'}))
        (target / 'LocalImport.qml').write_text('legacy UI retained until deliberate migration')
        (self.base / 'connections.json').write_text('untouched fixture configuration')
        self.args = types.SimpleNamespace(plugin_dir=target, bin_dir=self.base / 'bin',
            state_dir=self.base / 'state', install_binaries=True,
            helper=self.binary('miilo-owl', '1.4.0'), local=self.binary('miilo-local', '0.2.0'))

    def binary(self, name, version):
        path = self.base / name
        path.write_text(f'#!/bin/sh\n[ "$1" = "--version" ] || exit 99\nprintf "%s\\n" "{name} {version}"\n')
        path.chmod(0o755)
        return path

    def test_installs_native_ui_backs_up_and_preserves_data(self):
        INSTALL.install(self.args)
        manifest = json.loads((self.args.plugin_dir / 'manifest.json').read_text())
        self.assertEqual(manifest['entryPoints']['barWidget'], 'ui/shell/BarWidget.qml')
        self.assertEqual((self.args.plugin_dir / 'assets/70-miilo-fleet.owl').read_bytes(),
                         (ROOT / 'assets/70-miilo-fleet.owl').read_bytes())
        self.assertEqual((self.base / 'connections.json').read_text(), 'untouched fixture configuration')
        backups = list(self.args.state_dir.glob('native-*'))
        self.assertEqual(len(backups), 1)
        self.assertIn('legacy UI', (backups[0] / 'io.miilo.bar/LocalImport.qml').read_text())
        self.assertTrue(json.loads((backups[0] / 'installed.json').read_text())['files'])
        self.assertEqual((self.args.bin_dir / 'miilo-local').read_bytes(), self.args.local.read_bytes())

    def test_stale_binary_stops_before_touching_plugin(self):
        self.args.helper = self.binary('miilo-owl', '1.3.0')
        with self.assertRaisesRegex(ValueError, 'rebuild'):
            INSTALL.install(self.args)
        self.assertFalse((self.args.plugin_dir / 'ui').exists())
        self.assertFalse(self.args.state_dir.exists())

    def test_git_checkout_is_not_overwritten(self):
        (self.args.plugin_dir / '.git').mkdir()
        with self.assertRaisesRegex(ValueError, 'Git checkout'):
            INSTALL.install(self.args)
        self.assertFalse(self.args.state_dir.exists())

    def test_managed_symlink_is_not_followed(self):
        outside = self.base / 'unrelated'
        outside.mkdir()
        (self.args.plugin_dir / 'assets').symlink_to(outside, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, 'symlink'):
            INSTALL.install(self.args)
        self.assertEqual(list(outside.iterdir()), [])


if __name__ == '__main__':
    unittest.main()
