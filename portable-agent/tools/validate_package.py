#!/usr/bin/env python3
"""Static package integrity checks; no agent behavior/runtime claims."""
from pathlib import Path
import hashlib, json, re, sys
ROOT=Path(__file__).resolve().parents[1]
errors=[]
canonical=sorted(p.stem for p in (ROOT/'skills').glob('*.md') if p.name not in {'REGISTRY.md','LEGACY-INVENTORY.md'})
for host in ('claude','codex'):
    base=ROOT/'adapters'/host/'skills'
    actual=sorted(p.name for p in base.iterdir() if p.is_dir()) if base.exists() else []
    if actual!=canonical: errors.append(f'{host} adapter skill parity mismatch')
    for name in canonical:
        pointer=base/name/'SKILL.md'
        if not pointer.is_file():
            errors.append(f'bad/missing pointer: {host}/{name}')
            continue
        content=pointer.read_text(encoding='utf-8')
        match=re.search(r'canonical skill `([^`]+)`',content)
        if not match:
            errors.append(f'canonical target missing: {host}/{name}')
            continue
        target=(pointer.parent/match.group(1)).resolve()
        if target != (ROOT/'skills'/f'{name}.md').resolve() or not target.is_file():
            errors.append(f'pointer target invalid: {host}/{name}')
routes=json.loads((ROOT/'evals/routing-cases.json').read_text(encoding='utf-8'))
scenarios=json.loads((ROOT/'evals/scenario-cases.json').read_text(encoding='utf-8'))
for fixture,label in ((routes,'routing'),(scenarios,'scenario')):
    ids=[c.get('id') for c in fixture]
    if len(ids)!=len(set(ids)): errors.append(f'duplicate {label} IDs')
    for c in fixture:
        required=('id','input','expected_workflow','expected_skills','forbidden','rationale') if label=='routing' else ('id','input','workflow','expected_skills','forbidden','acceptance')
        if not all(c.get(k) for k in required): errors.append(f'incomplete {label} case: {c.get("id")}')
        wf=c.get('expected_workflow') if label=='routing' else c.get('workflow')
        if wf and not (ROOT/wf).is_file(): errors.append(f'missing workflow: {wf}')
        for skill in c.get('expected_skills',[]):
            if not (ROOT/'skills'/f'{skill}.md').is_file(): errors.append(f'unknown skill: {skill}')
if {c['id'] for c in routes} != {c['id'] for c in scenarios}: errors.append('routing/scenario IDs differ')
legacy=(ROOT/'skills/LEGACY-INVENTORY.md').read_text(encoding='utf-8')
if len(re.findall(r'^\| `[^`]+` \|',legacy,re.M))!=63: errors.append('legacy inventory count != 63')
# Validate all textual formats and relative Markdown links
for f in ROOT.rglob('*'):
    if not f.is_file() or '__pycache__' in f.parts or f.suffix=='.pyc': continue
    rel=f.relative_to(ROOT).as_posix()
    if f.suffix in {'.md','.json','.py','.txt'}:
        b=f.read_bytes()
        if not b.endswith(b'\n'): errors.append(f'missing final newline: {rel}')
        try: b.decode('utf-8')
        except UnicodeDecodeError: errors.append(f'invalid UTF-8: {rel}')
    if f.suffix=='.json':
        try: json.loads(f.read_text(encoding='utf-8'))
        except Exception as exc: errors.append(f'invalid JSON {rel}: {exc}')
for f in ROOT.rglob('*.md'):
    for target in re.findall(r'\[[^]]+\]\(([^)]+)\)',f.read_text(encoding='utf-8')):
        if target.startswith(('http://','https://','mailto:','#')): continue
        path=target.split('#',1)[0]
        if path and not (f.parent/path).exists(): errors.append(f'broken link: {f.relative_to(ROOT)} -> {target}')
manifest_file=ROOT/'manifest/FILE-MANIFEST.json'
if manifest_file.exists():
    manifest=json.loads(manifest_file.read_text(encoding='utf-8'))
    entries=manifest.get('files',[])
    listed={e['path'] for e in entries if isinstance(e,dict) and 'path' in e}
    actual={f.relative_to(ROOT).as_posix() for f in ROOT.rglob('*') if f.is_file() and '__pycache__' not in f.parts and f.suffix!='.pyc' and f.relative_to(ROOT).as_posix() not in {'manifest/FILE-MANIFEST.json','manifest/SHA256SUMS'}}
    if actual-listed: errors.append('manifest missing: '+', '.join(sorted(actual-listed)))
    if listed-actual: errors.append('manifest stale: '+', '.join(sorted(listed-actual)))
    for entry in entries:
        path=ROOT/entry['path']
        if path.exists():
            if entry.get('sha256')!=hashlib.sha256(path.read_bytes()).hexdigest(): errors.append('hash mismatch: '+entry['path'])
            if entry.get('bytes')!=path.stat().st_size: errors.append(f'size mismatch: {entry['path']}')
# Verify checksum list is complete and each checksum matches its named file.
checksum_file=ROOT/'manifest/SHA256SUMS'
if checksum_file.exists():
    parsed={}
    for line in checksum_file.read_text(encoding='utf-8').splitlines():
        parts=line.split('  ',1)
        if len(parts)==2: parsed[parts[1]]=parts[0]
    manifest_paths={e['path'] for e in entries if isinstance(e,dict) and 'path' in e}
    if parsed.keys()!=manifest_paths: errors.append('SHA256SUMS path set differs from manifest')
    for path,digest in parsed.items():
        file=ROOT/path
        if not file.exists() or hashlib.sha256(file.read_bytes()).hexdigest()!=digest: errors.append('checksum list mismatch: '+path)
if errors:
    print('FAIL'); print('\n'.join(errors)); sys.exit(1)
print(f'PASS: integrity, links, adapters, fixtures, manifest; {len(canonical)} canonical skills; {len(routes)} routes; 63 inventory entries')
