#!/usr/bin/env python3
"""Regenerate the portable-agent file manifest and SHA-256 checksum list."""
from pathlib import Path
import hashlib, json
ROOT=Path(__file__).resolve().parents[1]
EXCLUDED={'manifest/FILE-MANIFEST.json','manifest/SHA256SUMS'}
EXCLUDED_PREFIXES=('temp/deploylauncher-bin/','temp/deploylauncher-publish-check/')
def include(path):
    rel=path.relative_to(ROOT).as_posix()
    return (path.is_file() and '.git' not in path.parts and '__pycache__' not in path.parts
            and path.suffix!='.pyc' and rel not in EXCLUDED
            and not any(rel.startswith(prefix) for prefix in EXCLUDED_PREFIXES))
files=sorted(p for p in ROOT.rglob('*') if include(p))
entries=[]
for path in files:
    rel=path.relative_to(ROOT).as_posix()
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    entries.append({'path':rel,'sha256':digest,'bytes':path.stat().st_size})
version=(ROOT/'VERSION').read_text(encoding='utf-8').strip()
(ROOT/'manifest/FILE-MANIFEST.json').write_text(json.dumps({'version':version,'files':entries},indent=2)+'\n',encoding='utf-8')
(ROOT/'manifest/SHA256SUMS').write_text(''.join(f"{entry['sha256']}  {entry['path']}\n" for entry in entries),encoding='utf-8')
print(f'Generated {len(entries)} entries for version {version}.')
