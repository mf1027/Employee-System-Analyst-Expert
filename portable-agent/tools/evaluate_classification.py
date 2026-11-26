#!/usr/bin/env python3
"""Score externally produced agent classifications against routing fixtures.

The script never calls a model. Supply a JSON array with one object per fixture:
{"id": "bug", "intent": "bug_rca", "specialists": [], "support": ["test-strategy"]}
"""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path
sys_path = str(Path(__file__).resolve().parent)
if sys_path not in sys.path:
    sys.path.insert(0, sys_path)
from resolve_skills import resolve

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "evals" / "routing-cases.json"


def evaluate(candidate_path: Path) -> tuple[list[dict], bool]:
    expected = json.loads(FIXTURES.read_text(encoding="utf-8"))
    candidate = json.loads(candidate_path.read_text(encoding="utf-8"))
    if not isinstance(candidate, list):
        raise ValueError("candidate file must contain a JSON array")
    ids = [item.get("id") for item in candidate if isinstance(item, dict)]
    if len(ids) != len(candidate) or len(ids) != len(set(ids)):
        raise ValueError("candidate entries must be objects with unique IDs")
    expected_by_id = {item["id"]: item for item in expected}
    actual_by_id = {item["id"]: item for item in candidate}
    if set(actual_by_id) != set(expected_by_id):
        missing = sorted(set(expected_by_id) - set(actual_by_id))
        extra = sorted(set(actual_by_id) - set(expected_by_id))
        raise ValueError(f"candidate fixture IDs differ; missing={missing}; extra={extra}")

    results = []
    for fixture in expected:
        actual = actual_by_id[fixture["id"]]
        intent = actual.get("intent")
        specialists = actual.get("specialists", [])
        support = actual.get("support", [])
        decision = {key: actual.get(key) for key in (
            "dominant_intent", "primary_deliverable", "trigger_evidence",
            "specialist_evidence", "support_output_need", "excluded_candidates", "uncertainty"
        )}
        issues = []
        if intent != fixture["expected_intent"]:
            issues.append(f"intent expected {fixture['expected_intent']!r}, got {intent!r}")
        if sorted(set(specialists)) != sorted(fixture["specialists"]):
            issues.append(f"specialists expected {fixture['specialists']}, got {specialists}")
        if sorted(set(support)) != sorted(fixture["support"]):
            issues.append(f"support expected {fixture['support']}, got {support}")
        if not issues:
            try:
                result = resolve(intent, specialists, support, decision=decision)
                actual_skills = [item["id"] for item in result["skills"]]
                if result["workflow"] != fixture["expected_workflow"]:
                    issues.append(f"workflow mismatch: {result['workflow']}")
                if actual_skills != fixture["expected_skills"]:
                    issues.append(f"resolved skills expected {fixture['expected_skills']}, got {actual_skills}")
            except (ValueError, KeyError) as exc:
                issues.append(f"resolver rejected classification: {exc}")
        results.append({"id": fixture["id"], "passed": not issues, "issues": issues})
    return results, all(item["passed"] for item in results)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate_json", type=Path, help="JSON array of model-produced classifications")
    args = parser.parse_args()
    try:
        results, passed = evaluate(args.candidate_json)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    for item in results:
        status = "PASS" if item["passed"] else "FAIL"
        print(f"{status} {item['id']}")
        for issue in item["issues"]:
            print(f"  - {issue}")
    count = sum(item["passed"] for item in results)
    print(f"\nClassification score: {count}/{len(results)} ({count / len(results):.1%})")
    return 0 if passed else 1

if __name__ == "__main__":
    raise SystemExit(main())
