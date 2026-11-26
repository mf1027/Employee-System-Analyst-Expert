#!/usr/bin/env python3
"""Tests for the offline semantic-classification scoring harness."""
import importlib.util, json, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
TOOL=ROOT/'tools'/'evaluate_classification.py'
spec=importlib.util.spec_from_file_location('evaluate_classification',TOOL)
evaluator=importlib.util.module_from_spec(spec); spec.loader.exec_module(evaluator)
FIXTURES=json.loads((ROOT/'evals'/'routing-cases.json').read_text(encoding='utf-8'))

class ClassificationEvaluationTests(unittest.TestCase):
 def candidate(self):
  return [{'id':x['id'],'intent':x['expected_intent'],'specialists':x['specialists'],'support':x['support'],
   'dominant_intent':x['expected_intent'],'primary_deliverable':x['input'],'trigger_evidence':x['input'],
   'specialist_evidence':{s:'Evidence in the request requires this specialist.' for s in x['specialists']},
   'support_output_need':{s:'The request requires this distinct support output.' for s in x['support']},
   'excluded_candidates':x['forbidden'],'uncertainty':'No material ambiguity in this synthetic fixture.'} for x in FIXTURES]
 def write(self,data,tmp):
  path=Path(tmp)/'candidate.json'; path.write_text(json.dumps(data),encoding='utf-8'); return path
 def test_exact_fixture_classification_scores_full_pass(self):
  with tempfile.TemporaryDirectory() as tmp:
   results,passed=evaluator.evaluate(self.write(self.candidate(),tmp))
  self.assertTrue(passed)
  self.assertEqual(len(results),len(FIXTURES))
 def test_wrong_research_owner_is_detected(self):
  candidate=self.candidate()
  next(x for x in candidate if x['id']=='research')['intent']='capability_assessment'
  with tempfile.TemporaryDirectory() as tmp:
   results,passed=evaluator.evaluate(self.write(candidate,tmp))
  self.assertFalse(passed)
  failed=next(x for x in results if x['id']=='research')
  self.assertFalse(failed['passed'])
 def test_missing_or_extra_case_fails_closed(self):
  candidate=self.candidate()[:-1]
  with tempfile.TemporaryDirectory() as tmp:
   with self.assertRaisesRegex(ValueError,'fixture IDs differ'):
    evaluator.evaluate(self.write(candidate,tmp))
 def test_duplicate_case_id_fails_closed(self):
  candidate=self.candidate(); candidate.append(candidate[0])
  with tempfile.TemporaryDirectory() as tmp:
   with self.assertRaisesRegex(ValueError,'unique IDs'):
    evaluator.evaluate(self.write(candidate,tmp))

if __name__=='__main__': unittest.main(verbosity=2)
