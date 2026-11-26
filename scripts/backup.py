#!/usr/bin/env python3
"""Create and verify a client-data backup before applying retention."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import tempfile
import zipfile
from datetime import datetime
from pathlib import Path

TARGETS = ("memory/clients", ".claude-mem", "reference", "deliverables")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collect_files(root: Path, include_engines: bool) -> list[tuple[Path, str]]:
    targets = list(TARGETS) + (["engines"] if include_engines else [])
    files: list[tuple[Path, str]] = []
    for target in targets:
        base = root / target
        if not base.is_dir():
            continue
        for current, dirs, names in os.walk(base, followlinks=False):
            current_path = Path(current)
            for name in dirs:
                if (current_path / name).is_symlink():
                    raise RuntimeError(f"symbolic-link directory requires manual backup review: {current_path / name}")
            dirs[:] = sorted(
                name for name in dirs
                if not (name == ".claude-mem" and current_path != root / ".claude-mem")
            )
            for name in sorted(names):
                source = current_path / name
                if source.is_symlink():
                    raise RuntimeError(f"symbolic-link file requires manual backup review: {source}")
                relative = source.relative_to(root).as_posix()
                if ".claude-mem" in Path(relative).parts and not relative.startswith(".claude-mem/"):
                    continue
                files.append((source, relative))
    return files


def verify_archive(archive: Path) -> None:
    with zipfile.ZipFile(archive, "r") as bundle:
        bad = bundle.testzip()
        if bad:
            raise RuntimeError(f"archive CRC failure: {bad}")
        manifest = json.loads(bundle.read("BACKUP-MANIFEST.json"))
        expected = {item["path"]: item for item in manifest["files"]}
        actual = set(bundle.namelist()) - {"BACKUP-MANIFEST.json"}
        if actual != set(expected):
            raise RuntimeError("archive file list does not match its manifest")
        for name, item in expected.items():
            data = bundle.read(name)
            if len(data) != item["size"] or hashlib.sha256(data).hexdigest() != item["sha256"]:
                raise RuntimeError(f"archive verification failed: {name}")


def create_backup(root: Path, destination: Path, keep: int, include_engines: bool, stamp: str | None = None) -> Path:
    if keep < 1:
        raise ValueError("keep must be at least 1")
    root = root.resolve()
    destination.mkdir(parents=True, exist_ok=True)
    files = collect_files(root, include_engines)
    if not files:
        raise RuntimeError("nothing to back up: no files found in configured data folders")

    stamp = stamp or datetime.now().strftime("%Y-%m-%d_%H%M%S_%f")
    final_path = destination / f"employee-client-data_{stamp}.zip"
    fd, temp_name = tempfile.mkstemp(prefix=".employee-backup-", suffix=".tmp.zip", dir=destination)
    os.close(fd)
    temp_path = Path(temp_name)
    try:
        entries = []
        with zipfile.ZipFile(temp_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
            for source, relative in files:
                bundle.write(source, relative)
                entries.append({"path": relative, "size": source.stat().st_size, "sha256": sha256(source)})
            bundle.writestr("BACKUP-MANIFEST.json", json.dumps({"schema": 1, "files": entries}, indent=2) + "\n")
        verify_archive(temp_path)
        os.replace(temp_path, final_path)
    except Exception:
        temp_path.unlink(missing_ok=True)
        raise

    # Retention runs only after the newly created archive has passed full verification.
    backups = sorted(destination.glob("employee-client-data_*.zip"), key=lambda p: p.stat().st_mtime, reverse=True)
    for old in backups[keep:]:
        old.unlink()
    return final_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--destination", type=Path, default=Path.home() / "Documents" / "EmployeeBackups")
    parser.add_argument("--keep", type=int, default=int(os.environ.get("KEEP", "10")))
    parser.add_argument("--include-engines", action="store_true", default=os.environ.get("INCLUDE_ENGINES") == "1")
    args = parser.parse_args()
    try:
        output = create_backup(args.root, args.destination, args.keep, args.include_engines)
    except Exception as exc:
        print(f"[FAIL] Backup not committed; previous backups preserved: {exc}", file=sys.stderr)
        return 1
    print(f"[OK] Verified backup: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
