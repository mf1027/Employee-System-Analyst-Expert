#!/usr/bin/env python3
"""Fixture-connected structural/contract tests. Not a live model evaluation."""
from pathlib import Path
import json, re, unittest
ROOT=Path(__file__).resolve().parents[1]
ROUTES=json.loads((ROOT/'evals/routing-cases.json').read_text(encoding='utf-8'))
SCENARIOS=json.loads((ROOT/'evals/scenario-cases.json').read_text(encoding='utf-8'))
ADVERSARIAL=json.loads((ROOT/'evals/adversarial-cases.json').read_text(encoding='utf-8'))
class PackageContractTests(unittest.TestCase):
 def test_scenario_and_routing_fixtures_are_same_cases(self):
  self.assertEqual({x['id'] for x in ROUTES},{x['id'] for x in SCENARIOS})
 def test_every_route_has_existing_workflow_and_skill(self):
  for case in ROUTES:
   with self.subTest(case=case['id']):
    self.assertTrue((ROOT/case['expected_workflow']).is_file())
    for skill in case['expected_skills']: self.assertTrue((ROOT/'skills'/f'{skill}.md').is_file())
 def test_fixture_scenarios_have_nonempty_expectations(self):
  for case in SCENARIOS:
   with self.subTest(case=case['id']):
    self.assertTrue(case['input'].strip())
    self.assertTrue(case['acceptance'].strip())
    self.assertTrue(case['forbidden'])
 def test_all_clipboard_scenario_classes_have_explicit_route(self):
  expected={'new-project','existing-project','continuation','bug','feature','research','video','analysis-only','review','scope-change','blocked','skill-create','context-optimize','release','multi-agent','status'}
  self.assertEqual(expected,{c['id'] for c in ROUTES})
 def test_adversarial_suite_covers_authority_and_evidence(self):
  ids={c['id'] for c in ADVERSARIAL}
  expected={'no-approval-deploy','fake-test-claim','checkpoint-false-completion','schema-invention','scope-creep','blocked-loop','analysis-only-mutation','fake-delegation','host-unavailable','memory-parallel'}
  self.assertEqual(expected,ids)
 def test_core_contract_has_nonnegotiable_controls(self):
  text=(ROOT/'AGENT.md').read_text(encoding='utf-8').lower()
  for phrase in ('evidence first','existing-system-first','approval','route by task','stop safely','canonical memory','do not imply a skill was invoked'):
   with self.subTest(phrase=phrase): self.assertIn(phrase,text)
 def test_state_machine_and_resume_contract_exist(self):
  for path in ('workflows/state-machine.md','workflows/continuation-contract.md'):
   self.assertTrue((ROOT/path).is_file())
  states=(ROOT/'workflows/state-machine.md').read_text(encoding='utf-8')
  for state in ('Intake','Analysis','Planning','Ready','In Progress','Review','Blocked','Paused','Completed','Released'):
   self.assertIn(state,states)
 def test_analysis_only_explicitly_read_only(self):
  text=(ROOT/'workflows/analysis-only.md').read_text(encoding='utf-8').lower()
  self.assertIn('read-only',text)
  self.assertIn('no changes made',text)
 def test_release_gate_contains_authorization_and_rollback(self):
  text=(ROOT/'workflows/release.md').read_text(encoding='utf-8').lower()
  for phrase in ('approval','rollback','post-deployment','do not deploy'):
   self.assertIn(phrase,text)
 def test_multi_agent_ownership_and_independence(self):
  text=(ROOT/'workflows/multi-agent.md').read_text(encoding='utf-8').lower()
  for phrase in ('task owner','shared files','independent qa','never fabricate'):
   self.assertIn(phrase,text)
 def test_package_claims_do_not_overstate_live_runtime(self):
  text=(ROOT/'README.md').read_text(encoding='utf-8').lower()
  self.assertIn('do not invoke a model',text)
  self.assertTrue('no live runtime' in text or 'no target is runtime-certified' in text)
 def test_new_project_sop_has_baseline_and_ready_gate(self):
  text=(ROOT/'workflows/new-project.md').read_text(encoding='utf-8').lower()
  for phrase in ('requirements baseline','acceptance criteria','architecture','ready gate','handoff'):
   self.assertIn(phrase,text)
 def test_existing_project_requires_state_inspection(self):
  text=(ROOT/'workflows/existing-project.md').read_text(encoding='utf-8').lower()
  for phrase in ('current diff/status','baseline tests','reconcile current state','do not restart'):
   self.assertIn(phrase,text)
 def test_scope_change_has_approval_and_baseline_update(self):
  text=(ROOT/'workflows/scope-change.md').read_text(encoding='utf-8').lower()
  self.assertIn('explicit decision',text)
  self.assertIn('update canonical requirements',text)
 def test_blocked_flow_has_retry_limit_and_checkpoint(self):
  text=(ROOT/'workflows/blocked-task.md').read_text(encoding='utf-8').lower()
  self.assertIn('after two materially different',text)
  self.assertIn('checkpoint',text)
 def test_host_entry_points_if_present_defer_to_canonical_agent(self):
  paths=('AGENTS.md','.github/copilot-instructions.md','CLAUDE.md','GEMINI.md')
  present=[p for p in paths if (ROOT/p).is_file()]
  for path in present:
   with self.subTest(path=path):
    text=(ROOT/path).read_text(encoding='utf-8').lower()
    self.assertIn('agent.md',text)
    self.assertIn('canonical',text)
    self.assertIn('do not duplicate',text)
 def test_host_adapters_are_not_claimed_runtime_certified_without_evidence(self):
  text=(ROOT/'docs/INSTALLATION.md').read_text(encoding='utf-8').lower()
  for host in ('claude code','vs code github copilot','codex'):
   with self.subTest(host=host): self.assertIn(host,text)
  self.assertTrue('nothing in this table certifies' in text or 'no row is runtime-certified' in text)
 def test_optional_capabilities_have_explicit_fallback_guidance(self):
  text='\n'.join(p.read_text(encoding='utf-8').lower() for p in [ROOT/'AGENT.md',*sorted((ROOT/'workflows').glob('*.md')),*sorted((ROOT/'skills').glob('*.md'))])
  cases={
   'browser_or_web_search':(('search',),('unavailable',)),
   'persistent_memory_or_resume':(('memory',),('unavailable','checkpoint')),
   'delegation':(('delegation','multi-agent'),('unavailable','do not fan out')),
   'write_or_terminal_access':(('write','command'),('unavailable','permission')),
   'approval_or_permission_denial':(('permission','approval'),('stop safely','denied','require explicit')),
  }
  for label,(capabilities,fallbacks) in cases.items():
   with self.subTest(capability=label):
    self.assertTrue(any(word in text for word in capabilities),f'missing capability documentation: {capabilities}')
    self.assertTrue(any(word in text for word in fallbacks),f'missing safe fallback: {fallbacks}')
 def test_adapter_pointer_resolves_to_canonical_skill(self):
  for host in ('claude','codex'):
   adapter=ROOT/'adapters'/host/'skills'
   for skill in sorted(p.name for p in adapter.iterdir() if p.is_dir()):
    pointer=adapter/skill/'SKILL.md'
    content=pointer.read_text(encoding='utf-8')
    match=re.search(r'canonical skill `([^`]+)`',content)
    with self.subTest(host=host,skill=skill):
     self.assertIsNotNone(match)
     target=(pointer.parent/match.group(1)).resolve()
     self.assertTrue(target.is_relative_to(ROOT.resolve()))
     self.assertTrue(target.is_file())
     self.assertEqual(target, (ROOT/'skills'/f'{skill}.md').resolve())
 def test_canonical_agent_is_not_replaced_by_host_skill_pointers(self):
  text=(ROOT/'docs/ARCHITECTURE.md').read_text(encoding='utf-8').lower()
  self.assertIn('single source of truth',text)
  self.assertIn('direct the agent to `agent.md`',text)
 def test_host_adapter_docs_capture_current_discovery_constraints(self):
  text=(ROOT/'docs/INSTALLATION.md').read_text(encoding='utf-8').lower()
  for phrase in ('v2.1.277','claude.local.md','codex cli','copilot','no row is runtime-certified'):
   with self.subTest(phrase=phrase): self.assertIn(phrase,text)
 def test_adapter_readmes_provide_pointer_and_manual_fallback(self):
  for host in ('claude','codex','generic'):
   text=(ROOT/'adapters'/host/'README.md').read_text(encoding='utf-8').lower()
   with self.subTest(host=host):
    self.assertTrue('agent.md' in text or 'agent' in text)
    self.assertTrue('directly' in text or 'open' in text or 'explicitly ask' in text)
    self.assertTrue('no live' in text or 'no runtime' in text or 'not certified' in text or 'does not certify' in text)

