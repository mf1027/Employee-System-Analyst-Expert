import importlib.util
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

MODULE_PATH = Path(__file__).with_name('backup.py')
spec = importlib.util.spec_from_file_location('backup', MODULE_PATH)
backup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backup)


class BackupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / 'repo'
        self.dest = Path(self.temp.name) / 'backups'
        (self.root / 'memory/clients/acme/project').mkdir(parents=True)
        (self.root / 'memory/clients/acme/project/decisions.md').write_text('approved decision')
        nested = self.root / 'memory/clients/acme/.claude-mem'
        nested.mkdir()
        (nested / 'nested.log').write_text('exclude nested store')
        (self.root / '.claude-mem').mkdir()
        (self.root / '.claude-mem/events.jsonl').write_text('top-level store retained')
        (self.root / 'reference').mkdir()
        (self.root / 'reference/source.md').write_text('source')
        (self.root / 'engines').mkdir()
        (self.root / 'engines/tool.bin').write_bytes(b'engine')

    def tearDown(self):
        self.temp.cleanup()

    def test_archive_manifest_hashes_and_nested_store_exclusion(self):
        archive = backup.create_backup(self.root, self.dest, 5, False, '2026-11-26_100000')
        with zipfile.ZipFile(archive) as z:
            self.assertIsNone(z.testzip())
            names = set(z.namelist())
            self.assertIn('memory/clients/acme/project/decisions.md', names)
            self.assertIn('.claude-mem/events.jsonl', names)
            self.assertNotIn('memory/clients/acme/.claude-mem/nested.log', names)
            self.assertNotIn('engines/tool.bin', names)
        backup.verify_archive(archive)
        restored = Path(self.temp.name) / 'restored'
        with zipfile.ZipFile(archive) as z:
            z.extractall(restored)
        self.assertEqual((restored / 'memory/clients/acme/project/decisions.md').read_text(), 'approved decision')
        self.assertEqual((restored / '.claude-mem/events.jsonl').read_text(), 'top-level store retained')

    def test_failed_verification_preserves_previous_backups_and_removes_temp(self):
        self.dest.mkdir()
        previous = self.dest / 'employee-client-data_previous.zip'
        previous.write_bytes(b'known good')
        with patch.object(backup, 'verify_archive', side_effect=RuntimeError('simulated CRC failure')):
            with self.assertRaisesRegex(RuntimeError, 'simulated CRC failure'):
                backup.create_backup(self.root, self.dest, 1, False, '2026-11-26_100001')
        self.assertEqual(previous.read_bytes(), b'known good')
        self.assertEqual(list(self.dest.glob('employee-client-data_*.zip')), [previous])
        self.assertEqual(list(self.dest.glob('*.tmp.zip')), [])

    def test_symlink_source_fails_closed_and_preserves_existing_archive(self):
        self.dest.mkdir()
        previous = self.dest / 'employee-client-data_known-good.zip'
        previous.write_bytes(b'known good')
        outside = Path(self.temp.name) / 'outside.txt'
        outside.write_text('outside data')
        link = self.root / 'reference' / 'outside-link.txt'
        try:
            link.symlink_to(outside)
        except (OSError, NotImplementedError):
            self.skipTest('symlink creation is unavailable on this platform')
        with self.assertRaisesRegex(RuntimeError, 'symbolic-link'):
            backup.create_backup(self.root, self.dest, 1, False, '2026-11-26_100003')
        self.assertEqual(previous.read_bytes(), b'known good')
        self.assertEqual(list(self.dest.glob('employee-client-data_*.zip')), [previous])

    def test_retention_runs_only_after_verified_success(self):
        self.dest.mkdir()
        for name in ('employee-client-data_old1.zip', 'employee-client-data_old2.zip'):
            (self.dest / name).write_bytes(b'old archive')
        archive = backup.create_backup(self.root, self.dest, 2, True, '2026-11-26_100002')
        self.assertTrue(archive.exists())
        self.assertEqual(len(list(self.dest.glob('employee-client-data_*.zip'))), 2)
        with zipfile.ZipFile(archive) as z:
            self.assertIn('engines/tool.bin', z.namelist())


if __name__ == '__main__':
    unittest.main()
