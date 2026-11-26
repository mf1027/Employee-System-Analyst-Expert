#!/usr/bin/env python3
"""Build a deterministic, privacy-filtered production release ZIP and SHA-256."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import zipfile
from pathlib import Path

EXCLUDED_DIRS = {
    '.git', '.hg', '.svn', 'node_modules', '.venv', '.venv-soup', '__pycache__',
    '.pytest_cache', '.mypy_cache', '.ruff_cache', 'workspace', '.claude-mem', 'temp',
}
EXCLUDED_FILES = {'memory.md', 'improvement-backlog.md', 'RELEASE-MANIFEST.json'}
LOCAL_ONLY_DIRS = {'archive', 'clients', 'quarantine'}
LOCAL_ONLY_ROOTS = {'reference', 'deliverables', 'pdf-source', 'engines'}


def include(path: Path, root: Path) -> bool:
    rel = path.relative_to(root)
    parts = rel.parts
    if any(part in EXCLUDED_DIRS for part in parts):
        return False
    if any(part in LOCAL_ONLY_DIRS for part in parts):
        return False
    if parts[0] in LOCAL_ONLY_ROOTS and path.name != 'README.md':
        return False
    if path.name in EXCLUDED_FILES or path.suffix.lower() in {'.pyc', '.zip', '.pem', '.key', '.p12', '.pfx', '.sqlite', '.db', '.log'}:
        return False
    if path.name.startswith('.env') and path.name not in {'.env.example'}:
        return False
    if rel.as_posix().startswith('.claude/memory/gate/'):
        return False
    if rel.as_posix().startswith('temp/deploylauncher-bin/') or rel.as_posix().startswith('temp/deploylauncher-publish-check/'):
        return False
    return path.is_file() and not path.is_symlink()


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def build(root: Path, output: Path) -> tuple[str, int]:
    root, output = root.resolve(), output.resolve()
    if output == root or root in output.parents:
        raise ValueError('release output must be outside the source tree')
    version = (root / 'portable-agent/VERSION').read_text(encoding='utf-8').strip()
    files = sorted((p for p in root.rglob('*') if include(p, root)), key=lambda p: p.relative_to(root).as_posix())
    output.parent.mkdir(parents=True, exist_ok=True)
    temp = output.with_suffix(output.suffix + '.tmp')
    manifest = {'schema_version': 1, 'package': 'Employee-System-Analysis-Expert', 'version': version, 'files': []}
    try:
        with zipfile.ZipFile(temp, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for file in files:
                rel = file.relative_to(root).as_posix()
                data = file.read_bytes()
                manifest['files'].append({'path': rel, 'bytes': len(data), 'sha256': digest(data)})
                info = zipfile.ZipInfo(rel, date_time=(2020, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = (file.stat().st_mode & 0xFFFF) << 16
                archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
            info = zipfile.ZipInfo('RELEASE-MANIFEST.json', date_time=(2020, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, json.dumps(manifest, indent=2, sort_keys=True) + '\n')
        with zipfile.ZipFile(temp) as archive:
            if archive.testzip() is not None:
                raise RuntimeError('release ZIP CRC verification failed')
            stored = json.loads(archive.read('RELEASE-MANIFEST.json'))
            if len(stored['files']) != len(files):
                raise RuntimeError('release manifest file count mismatch')
            for entry in stored['files']:
                data = archive.read(entry['path'])
                if len(data) != entry['bytes'] or digest(data) != entry['sha256']:
                    raise RuntimeError(f"release manifest mismatch: {entry['path']}")
        os.replace(temp, output)
    except Exception:
        temp.unlink(missing_ok=True)
        raise
    sha = digest(output.read_bytes())
    checksum_path = output.with_suffix(output.suffix + '.sha256')
    checksum_path.write_text(f'{sha}  {output.name}\n', encoding='utf-8')
    return sha, len(files)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    sha, count = build(args.root, args.output)
    print(f'PASS: {args.output} ({count} files; SHA-256 {sha})')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
