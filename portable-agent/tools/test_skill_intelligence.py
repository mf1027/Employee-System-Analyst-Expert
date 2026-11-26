#!/usr/bin/env python3
"""Deterministic skill-intelligence resolver tests; no model calls are made."""
import json, subprocess, sys, unittest, tempfile, importlib.util
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
TOOL=ROOT/'tools'/'resolve_skills.py'
spec=importlib.util.spec_from_file_location('resolve_skills',TOOL)
resolver=importlib.util.module_from_spec(spec); spec.loader.exec_module(resolver)
CASES=json.loads((ROOT/'evals'/'skill-routing-cases.json').read_text(encoding='utf-8'))
class SkillResolverTests(unittest.TestCase):
 def run_resolver(self,*args,include_decision=True):
  command=[sys.executable,str(TOOL),*args]
  if include_decision and '--decision-json' not in args:
   intent=args[args.index('--intent')+1] if '--intent' in args else ''
   specialists=[args[i+1] for i,x in enumerate(args[:-1]) if x=='--specialist']
   support=[args[i+1] for i,x in enumerate(args[:-1]) if x=='--support']
   decision={'dominant_intent':intent,'primary_deliverable':'Produce the task-specific primary deliverable.','trigger_evidence':'The request explicitly asks for this task outcome.','specialist_evidence':{x:'The task evidence requires this specialist output.' for x in specialists},'support_output_need':{x:'This distinct supporting output is needed.' for x in support},'excluded_candidates':[],'uncertainty':'No material ambiguity identified in this fixture.'}
   command += ['--decision-json',json.dumps(decision)]
  command += ['--json']
  return subprocess.run(command,capture_output=True,text=True,timeout=10)
 def test_all_routing_fixtures_resolve_exactly(self):
  for case in CASES:
   decision={'dominant_intent':case['intent'],'primary_deliverable':case['id'],'trigger_evidence':case['id'],'specialist_evidence':{x:'Fixture evidence requires this specialist output.' for x in case['specialists']},'support_output_need':{x:'Fixture requires this distinct support output.' for x in case['support']},'excluded_candidates':[],'uncertainty':'Fixture expectation only.'}
   with self.subTest(case=case['id']):
    data=resolver.resolve(case['intent'],case['specialists'],case['support'],decision=decision)
    self.assertEqual(data['workflow'],case['workflow'])
    self.assertEqual([x['id'] for x in data['skills']],case['expected'])
    self.assertEqual(sum(x['role']=='primary' for x in data['skills']),1)
 def test_decision_record_is_mandatory(self):
  r=self.run_resolver('--intent','requirements',include_decision=False)
  self.assertEqual(r.returncode,2)
  self.assertIn('--decision-json',r.stderr)
 def test_decision_record_must_match_intent(self):
  decision={'dominant_intent':'research','primary_deliverable':'x','trigger_evidence':'y','specialist_evidence':{},'support_output_need':{},'excluded_candidates':[],'uncertainty':'none'}
  r=subprocess.run([sys.executable,str(TOOL),'--intent','requirements','--decision-json',json.dumps(decision),'--json'],capture_output=True,text=True)
  self.assertEqual(r.returncode,2); self.assertIn('does not match',r.stderr)
 def test_decision_requires_exact_specialist_evidence(self):
  decision={'dominant_intent':'requirements','primary_deliverable':'Requirements baseline','trigger_evidence':'User asks for requirements','specialist_evidence':{'database':'DB evidence'},'support_output_need':{},'excluded_candidates':[],'uncertainty':'none'}
  r=subprocess.run([sys.executable,str(TOOL),'--intent','requirements','--decision-json',json.dumps(decision),'--json'],capture_output=True,text=True)
  self.assertEqual(r.returncode,2); self.assertIn('specialist_evidence keys',r.stderr)
 def test_decision_requires_exact_support_evidence(self):
  decision={'dominant_intent':'requirements','primary_deliverable':'Requirements baseline','trigger_evidence':'User asks for requirements','specialist_evidence':{},'support_output_need':{},'excluded_candidates':[],'uncertainty':'none'}
  r=subprocess.run([sys.executable,str(TOOL),'--intent','requirements','--support','test-strategy','--decision-json',json.dumps(decision),'--json'],capture_output=True,text=True)
  self.assertEqual(r.returncode,2); self.assertIn('support_output_need keys',r.stderr)
 def test_decision_cannot_both_select_and_exclude_skill(self):
  decision={'dominant_intent':'requirements','primary_deliverable':'Requirements baseline','trigger_evidence':'User asks for requirements','specialist_evidence':{},'support_output_need':{},'excluded_candidates':['requirements-analysis'],'uncertainty':'none'}
  r=subprocess.run([sys.executable,str(TOOL),'--intent','requirements','--decision-json',json.dumps(decision),'--json'],capture_output=True,text=True,timeout=10)
  self.assertEqual(r.returncode,2); self.assertIn('both selects and excludes',r.stderr)
 def test_maximum_allowed_selection_is_exactly_six_unique_skills(self):
  r=self.run_resolver('--intent','bug_rca','--specialist','database','--specialist','security','--specialist','domain','--support','risk-management','--support','test-strategy')
  self.assertEqual(r.returncode,0,r.stderr)
  data=json.loads(r.stdout)
  self.assertEqual(len(data['skills']),6)
  self.assertEqual(sum(x['role']=='primary' for x in data['skills']),1)
 def test_specialist_limit_fails_closed(self):
  r=self.run_resolver('--intent','comprehensive_analysis','--specialist','database','--specialist','security','--specialist','api','--specialist','domain')
  self.assertEqual(r.returncode,2); self.assertIn('maximum is 3',r.stderr)
 def test_support_limit_fails_closed(self):
  r=self.run_resolver('--intent','comprehensive_analysis','--support','risk-management','--support','test-strategy','--support','documentation-handover')
  self.assertEqual(r.returncode,2); self.assertIn('maximum is 2',r.stderr)
 def test_redundant_selection_is_reported(self):
  r=self.run_resolver('--intent','database_analysis','--specialist','database','--support','database-analysis')
  self.assertEqual(r.returncode,0,r.stderr)
  data=json.loads(r.stdout)
  self.assertEqual(len(data['skills']),1)
  self.assertEqual(data['suppressed'],[
   {'id':'database-analysis','requested_role':'specialist','winning_role':'primary','reason':'same canonical skill already selected; higher-precedence role retained'},
   {'id':'database-analysis','requested_role':'support','winning_role':'primary','reason':'same canonical skill already selected; higher-precedence role retained'}
  ])
 def test_catalog_rejects_duplicate_canonical_ids(self):
  data=json.loads((ROOT/'skills'/'skill-intelligence.json').read_text(encoding='utf-8'))
  data['canonical_skills'].append(data['canonical_skills'][0])
  with tempfile.TemporaryDirectory() as tmp:
   path=Path(tmp)/'catalog.json'; path.write_text(json.dumps(data),encoding='utf-8')
   with self.assertRaisesRegex(ValueError,'duplicate IDs'):
    resolver.load_catalog(path)
 def test_catalog_rejects_inconsistent_skill_contracts(self):
  data=json.loads((ROOT/'skills'/'skill-intelligence.json').read_text(encoding='utf-8'))
  data['skill_contracts'].pop(next(iter(data['skill_contracts'])))
  with tempfile.TemporaryDirectory() as tmp:
   path=Path(tmp)/'catalog.json'; path.write_text(json.dumps(data),encoding='utf-8')
   with self.assertRaisesRegex(ValueError,'exactly every canonical skill'):
    resolver.load_catalog(path)
 def test_catalog_rejects_missing_classification_contract(self):
  data=json.loads((ROOT/'skills'/'skill-intelligence.json').read_text(encoding='utf-8'))
  data['classification_contract'].pop('required_decision_fields')
  with tempfile.TemporaryDirectory() as tmp:
   path=Path(tmp)/'catalog.json'; path.write_text(json.dumps(data),encoding='utf-8')
   with self.assertRaisesRegex(ValueError,'classification_contract'):
    resolver.load_catalog(path)
 def test_catalog_rejects_non_single_primary_policy(self):
  data=json.loads((ROOT/'skills'/'skill-intelligence.json').read_text(encoding='utf-8'))
  data['resolution_policy']['one_primary_only']=False
  with tempfile.TemporaryDirectory() as tmp:
   path=Path(tmp)/'catalog.json'; path.write_text(json.dumps(data),encoding='utf-8')
   with self.assertRaisesRegex(ValueError,'exactly one primary'):
    resolver.load_catalog(path)
 def test_catalog_rejects_path_escape(self):
  data=json.loads((ROOT/'skills'/'skill-intelligence.json').read_text(encoding='utf-8'))
  data['host_compatibility']['claude']['adapter_root']='../../outside'
  with tempfile.TemporaryDirectory() as tmp:
   path=Path(tmp)/'catalog.json'; path.write_text(json.dumps(data),encoding='utf-8')
   with self.assertRaisesRegex(ValueError,'adapter_root is invalid'):
    resolver.load_catalog(path)
 def test_unknown_intent_fails_closed(self):
  r=self.run_resolver('--intent','guess')
  self.assertEqual(r.returncode,2); self.assertIn('unknown intent',r.stderr)
 def test_unknown_specialist_fails_closed(self):
  r=self.run_resolver('--intent','requirements','--specialist','magic')
  self.assertEqual(r.returncode,2); self.assertIn('unknown specialist',r.stderr)
 def test_unknown_support_skill_fails_closed(self):
  r=self.run_resolver('--intent','requirements','--support','not-a-skill')
  self.assertEqual(r.returncode,2); self.assertIn('unknown support skill',r.stderr)
 def test_duplicates_are_deduplicated_and_primary_role_wins(self):
  r=self.run_resolver('--intent','database_analysis','--specialist','database','--support','database-analysis')
  self.assertEqual(r.returncode,0,r.stderr)
  skills=json.loads(r.stdout)['skills']
  self.assertEqual(len(skills),1); self.assertEqual(skills[0]['role'],'primary')
 def test_every_canonical_skill_is_present_and_nonempty(self):
  data=json.loads((ROOT/'skills'/'skill-intelligence.json').read_text(encoding='utf-8'))
  self.assertEqual(set(data['canonical_skills']),{p.stem for p in (ROOT/'skills').glob('*.md') if p.name not in {'REGISTRY.md','LEGACY-INVENTORY.md'}})
  for name in data['canonical_skills']:
   with self.subTest(skill=name): self.assertTrue((ROOT/'skills'/f'{name}.md').is_file())
 def test_legacy_inventory_is_complete_and_source_status_is_truthful(self):
  data=json.loads((ROOT/'skills'/'skill-intelligence.json').read_text(encoding='utf-8'))
  self.assertEqual(len(data['legacy_parity']),63)
  missing=[x['name'] for x in data['legacy_parity'] if not x['source_available']]
  self.assertEqual(set(missing),{'apk-standalone-conversion','multi-agent-skill-propagation'})
 def test_reference_ingestion_is_not_web_research_or_video(self):
  data=json.loads((ROOT/'skills/skill-intelligence.json').read_text(encoding='utf-8'))
  self.assertEqual(data['intents']['reference_ingestion']['primary_skill'],'context-economy')
  case=next(x for x in CASES if x['id']=='reference-ingestion')
  self.assertEqual(case['expected'],['context-economy','documentation-handover'])
 def test_research_and_reach_have_distinct_ownership(self):
  data=json.loads((ROOT/'skills/skill-intelligence.json').read_text(encoding='utf-8'))
  self.assertEqual(data['intents']['research']['primary_skill'],'web-research')
  self.assertEqual(data['specialists']['research']['skill'],'agent-reach')
  self.assertNotEqual(data['intents']['research']['primary_skill'],data['specialists']['research']['skill'])
 def test_host_adapter_resolution_is_explicit_but_not_certified(self):
  for host,expected in [('claude','adapters/claude/skills/requirements-analysis/SKILL.md'),('codex','adapters/codex/skills/requirements-analysis/SKILL.md'),('generic',None)]:
   r=self.run_resolver('--intent','requirements','--host',host)
   self.assertEqual(r.returncode,0,r.stderr)
   data=json.loads(r.stdout)
   self.assertIn('unverified' if host!='generic' else 'unknown',data['host_status'])
   self.assertEqual(data['skills'][0]['adapter_pointer'],expected)
 def test_unknown_host_fails_closed(self):
  r=self.run_resolver('--intent','requirements','--host','unknown')
  self.assertEqual(r.returncode,2); self.assertIn('unknown host',r.stderr)
 def test_each_canonical_skill_has_ownership_contract(self):
  data=json.loads((ROOT/'skills/skill-intelligence.json').read_text(encoding='utf-8'))
  self.assertEqual(set(data['skill_contracts']),set(data['canonical_skills']))
  for name,contract in data['skill_contracts'].items():
   with self.subTest(skill=name):
    for field in ('purpose','owns','excludes','output','load_rule'): self.assertTrue(contract[field].strip())
 def test_no_implicit_text_classifier_or_permission_claim(self):
  data=json.loads((ROOT/'skills'/'skill-intelligence.json').read_text(encoding='utf-8'))
  self.assertTrue(data['classification_contract']['must_not_use_keyword_matching_as_authority'])
  self.assertIn('does not classify free text',data['purpose'])
if __name__=='__main__': unittest.main(verbosity=2)
