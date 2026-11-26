#!/usr/bin/env python3
"""Static package integrity checks; no agent behavior/runtime claims."""
from pathlib import Path
import hashlib, json, re, sys
ROOT=Path(__file__).resolve().parents[1]
errors=[]
EXCLUDED_PREFIXES=('temp/deploylauncher-bin/','temp/deploylauncher-publish-check/')
def included_file(path):
    rel=path.relative_to(ROOT).as_posix()
    return path.is_file() and '.git' not in path.parts and '__pycache__' not in path.parts and path.suffix!='.pyc' and not any(rel.startswith(prefix) for prefix in EXCLUDED_PREFIXES)
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
# Phase 2: Skill body depth and anti-duplication checks
registry_text=(ROOT/'skills/REGISTRY.md').read_text(encoding='utf-8')
for skill_name in canonical:
    skill_path=ROOT/'skills'/f'{skill_name}.md'
    body=skill_path.read_text(encoding='utf-8').strip()
    body_lines=body.split('\n')
    if len(body_lines)<10: errors.append(f'skill body too thin (<10 lines): {skill_name}')
    if len(body)<500: errors.append(f'skill body too short (<500 chars): {skill_name}')
    # Anti-duplication: body (minus heading) should NOT be a substring of the registry row
    body_no_heading='\n'.join(body_lines[1:]).strip()
    for row in registry_text.split('\n'):
        if f'`{skill_name}`' in row and body_no_heading and len(body_no_heading)<300:
            if body_no_heading in row:
                errors.append(f'skill body duplicates registry description: {skill_name}')
    required_sections=['## Purpose','## Procedure','## Output']
    for section in required_sections:
        if section not in body: errors.append(f'skill missing {section}: {skill_name}')
legacy=(ROOT/'skills/LEGACY-INVENTORY.md').read_text(encoding='utf-8')
if len(re.findall(r'^\| `[^`]+` \|',legacy,re.M))!=63: errors.append('legacy inventory count != 63')
# Deterministic skill-intelligence contract and fixture validation.
try:
    catalog=json.loads((ROOT/'skills/skill-intelligence.json').read_text(encoding='utf-8'))
    if catalog.get('schema_version') != 2: errors.append('skill-intelligence schema_version must be 2')
    if set(catalog.get('canonical_skills',[])) != set(canonical): errors.append('skill-intelligence canonical skill set mismatch')
    if set(catalog.get('skill_contracts',{})) != set(canonical): errors.append('skill_contracts canonical parity mismatch')
    for skill,contract in catalog.get('skill_contracts',{}).items():
        if not all(str(contract.get(field,'')).strip() for field in ('purpose','owns','excludes','output','load_rule')): errors.append(f'incomplete skill contract: {skill}')
    for intent,spec in catalog.get('intents',{}).items():
        if spec.get('primary_skill') not in canonical: errors.append(f'invalid primary skill for intent {intent}')
        if not (ROOT/'workflows'/f"{spec.get('workflow','')}.md").is_file(): errors.append(f'invalid workflow for intent {intent}')
    if set(catalog.get('host_compatibility',{})) != {'claude','codex','generic'}: errors.append('host compatibility profiles incomplete')
    policy=catalog.get('resolution_policy',{})
    for key in ('max_specialists','max_support_skills','max_unique_skills'):
        if not isinstance(policy.get(key),int) or isinstance(policy.get(key),bool) or policy[key] < 0: errors.append(f'invalid resolver limit: {key}')
    if policy.get('max_specialists') != 3 or policy.get('max_support_skills') != 2 or policy.get('max_unique_skills') != 6: errors.append('resolver selection limits differ from approved bounded-loading contract')
    classification=catalog.get('classification_contract',{})
    required_decision={'dominant_intent','primary_deliverable','trigger_evidence','specialist_evidence','support_output_need','excluded_candidates','uncertainty'}
    if set(classification.get('required_decision_fields',[])) != required_decision: errors.append('semantic classification decision contract incomplete')
    for specialist,spec in catalog.get('specialists',{}).items():
        if spec.get('skill') not in canonical: errors.append(f'invalid specialist skill: {specialist}')
    parity=catalog.get('legacy_parity',[])
    if len(parity)!=63 or len({x.get('name') for x in parity})!=63: errors.append('skill-intelligence legacy parity must contain 63 unique names')
    for item in parity:
        if item.get('source_available') and (not item.get('source_path') or not (ROOT.parent/item['source_path']).is_file()): errors.append(f"legacy source marked available but missing: {item.get('name')}")
        if not item.get('source_available') and item.get('source_path') is not None: errors.append(f"legacy source marked missing but path supplied: {item.get('name')}")
        if item.get('disposition') not in {'RESTORE','MERGE','REPLACE','REFERENCE','RETIRE','HOST-DEPENDENT'}: errors.append(f"invalid legacy disposition: {item.get('name')}")
    if {x.get('name') for x in parity if not x.get('source_available')} != {'apk-standalone-conversion','multi-agent-skill-propagation'}: errors.append('historical missing-source inventory changed; re-audit source parity')
    skill_cases=json.loads((ROOT/'evals/skill-routing-cases.json').read_text(encoding='utf-8'))
    case_ids=[x.get('id') for x in skill_cases]
    if len(case_ids)!=len(set(case_ids)): errors.append('duplicate skill-routing fixture IDs')
    for case in skill_cases:
        if case.get('intent') not in catalog.get('intents',{}): errors.append(f"unknown fixture intent: {case.get('id')}")
        if len(case.get('expected',[]))==0 or len(case.get('expected',[]))!=len(set(case.get('expected',[]))): errors.append(f"bad expected skills: {case.get('id')}")
        if sum(1 for name in case.get('expected',[]) if name==catalog['intents'][case['intent']]['primary_skill'])!=1: errors.append(f"fixture missing primary skill: {case.get('id')}")
    route_cases=json.loads((ROOT/'evals/routing-cases.json').read_text(encoding='utf-8'))
    route_intents=[x.get('expected_intent') for x in route_cases]
    if len(route_cases) != len(catalog.get('intents',{})) or set(route_intents) != set(catalog.get('intents',{})) or len(route_intents) != len(set(route_intents)): errors.append('natural-language routing fixtures must cover every primary intent exactly once')
    if len({x.get('id') for x in route_cases}) != len(route_cases): errors.append('duplicate natural-language route fixture IDs')
    adversarial=json.loads((ROOT/'evals/adversarial-cases.json').read_text(encoding='utf-8'))
    if len(adversarial) != 16 or len({x.get('id') for x in adversarial}) != 16: errors.append('adversarial fixture set must contain 16 unique cases')
    for case in route_cases:
        intent=case.get('expected_intent')
        if intent not in catalog.get('intents',{}): errors.append(f"unknown natural-language route intent: {case.get('id')}")
        if case.get('expected_workflow') != f"workflows/{catalog.get('intents',{}).get(intent,{}).get('workflow','')}.md": errors.append(f"route workflow/intent mismatch: {case.get('id')}")
        if len(set(case.get('specialists',[]))) > policy.get('max_specialists',0): errors.append(f"route exceeds specialist limit: {case.get('id')}")
        if len(set(case.get('support',[]))) > policy.get('max_support_skills',0): errors.append(f"route exceeds support limit: {case.get('id')}")
        expected_ids=[catalog.get('intents',{}).get(intent,{}).get('primary_skill')]
        expected_ids += [catalog.get('specialists',{}).get(s,{}).get('skill') for s in sorted(set(case.get('specialists',[])))]
        expected_ids += sorted(set(case.get('support',[])))
        expected_ids=list(dict.fromkeys(expected_ids))
        if expected_ids != case.get('expected_skills'): errors.append(f"route expected skill list differs from resolver policy: {case.get('id')}")
except Exception as exc: errors.append(f'skill-intelligence validation error: {exc}')
# Validate all textual formats and relative Markdown links
for f in ROOT.rglob('*'):
    if not included_file(f): continue
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
    actual={f.relative_to(ROOT).as_posix() for f in ROOT.rglob('*') if included_file(f) and f.relative_to(ROOT).as_posix() not in {'manifest/FILE-MANIFEST.json','manifest/SHA256SUMS'}}
    if actual-listed: errors.append('manifest missing: '+', '.join(sorted(actual-listed)))
    if listed-actual: errors.append('manifest stale: '+', '.join(sorted(listed-actual)))
    for entry in entries:
        path=ROOT/entry['path']
        if path.exists():
            if entry.get('sha256')!=hashlib.sha256(path.read_bytes()).hexdigest(): errors.append('hash mismatch: '+entry['path'])
            if entry.get('bytes')!=path.stat().st_size: errors.append(f"size mismatch: {entry['path']}")
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
print(f'PASS: integrity, links, adapters, fixtures, skill intelligence, manifest; {len(canonical)} canonical skills; {len(routes)} workflow routes; 63 legacy parity entries')
