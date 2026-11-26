#!/usr/bin/env python3
"""Validate and deterministically order an agent-classified skill selection.

This tool does not classify free text, load files, grant permissions, or enforce
model compliance. Semantic classification remains an explicit agent decision.
"""
from __future__ import annotations

import argparse
from functools import lru_cache
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "skills" / "skill-intelligence.json"
SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
REQUIRED_CONTRACT_FIELDS = ("purpose", "owns", "excludes", "output", "load_rule")


def _inside(path: Path, parent: Path) -> bool:
    try:
        path.resolve().relative_to(parent.resolve())
        return True
    except ValueError:
        return False


@lru_cache(maxsize=8)
def load_catalog(catalog_path: Path = CATALOG) -> tuple[dict[str, Any], set[str]]:
    """Load and validate the complete routing catalog before resolving anything."""
    data = json.loads(catalog_path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or data.get("schema_version") != 2:
        raise ValueError("unsupported or missing skill catalog schema_version (expected 2)")

    canonical_list = data.get("canonical_skills")
    if not isinstance(canonical_list, list) or not canonical_list:
        raise ValueError("canonical_skills must be a non-empty list")
    if any(not isinstance(x, str) or not SLUG.fullmatch(x) for x in canonical_list):
        raise ValueError("canonical_skills contains an invalid skill ID")
    if len(canonical_list) != len(set(canonical_list)):
        raise ValueError("canonical_skills contains duplicate IDs")
    canonical = set(canonical_list)

    for skill in canonical:
        path = ROOT / "skills" / f"{skill}.md"
        if not _inside(path, ROOT / "skills") or not path.is_file():
            raise ValueError(f"canonical skill file missing or outside skill root: {skill}")

    contracts = data.get("skill_contracts")
    if not isinstance(contracts, dict) or set(contracts) != canonical:
        raise ValueError("skill_contracts must contain exactly every canonical skill")
    for skill, contract in contracts.items():
        if not isinstance(contract, dict) or any(
            not isinstance(contract.get(field), str) or not contract[field].strip()
            for field in REQUIRED_CONTRACT_FIELDS
        ):
            raise ValueError(f"incomplete skill ownership contract: {skill}")

    intents = data.get("intents")
    if not isinstance(intents, dict) or not intents:
        raise ValueError("intents must be a non-empty object")
    for intent, spec in intents.items():
        if not isinstance(intent, str) or not SLUG.fullmatch(intent.replace("_", "-")):
            raise ValueError(f"invalid intent ID: {intent!r}")
        if not isinstance(spec, dict) or spec.get("primary_skill") not in canonical:
            raise ValueError(f"invalid primary skill for intent: {intent}")
        workflow = spec.get("workflow")
        workflow_path = ROOT / "workflows" / f"{workflow}.md"
        if not isinstance(workflow, str) or not SLUG.fullmatch(workflow) or not _inside(workflow_path, ROOT / "workflows") or not workflow_path.is_file():
            raise ValueError(f"invalid or missing workflow for intent: {intent}")

    specialists = data.get("specialists")
    if not isinstance(specialists, dict) or not specialists:
        raise ValueError("specialists must be a non-empty object")
    for specialist, spec in specialists.items():
        if not isinstance(specialist, str) or not SLUG.fullmatch(specialist.replace("_", "-")):
            raise ValueError(f"invalid specialist ID: {specialist!r}")
        if not isinstance(spec, dict) or spec.get("skill") not in canonical or not isinstance(spec.get("when"), str) or not spec["when"].strip():
            raise ValueError(f"invalid specialist definition: {specialist}")

    classification = data.get("classification_contract")
    required_decision_fields = {
        "dominant_intent", "primary_deliverable", "trigger_evidence",
        "specialist_evidence", "support_output_need", "excluded_candidates", "uncertainty"
    }
    if not isinstance(classification, dict) or set(classification.get("required_decision_fields", [])) != required_decision_fields:
        raise ValueError("classification_contract decision fields are incomplete or unsupported")

    policy = data.get("resolution_policy")
    if not isinstance(policy, dict) or policy.get("one_primary_only") is not True:
        raise ValueError("resolution_policy must enforce exactly one primary")
    if "fail closed" not in str(policy.get("unknown_intent_or_skill", "")).lower():
        raise ValueError("resolution_policy must fail closed for unknown identifiers")
    limits = ("max_specialists", "max_support_skills", "max_unique_skills")
    if any(not isinstance(policy.get(k), int) or isinstance(policy.get(k), bool) or policy[k] < 0 for k in limits):
        raise ValueError("resolution_policy limits must be non-negative integers")
    if policy["max_unique_skills"] < 1 or policy["max_unique_skills"] > 1 + policy["max_specialists"] + policy["max_support_skills"]:
        raise ValueError("max_unique_skills is inconsistent with the role limits")

    hosts = data.get("host_compatibility")
    if not isinstance(hosts, dict) or set(hosts) != {"claude", "codex", "generic"}:
        raise ValueError("host_compatibility must define claude, codex and generic")
    for host, spec in hosts.items():
        if not isinstance(spec, dict) or not isinstance(spec.get("status"), str):
            raise ValueError(f"invalid host profile: {host}")
        adapter_root = spec.get("adapter_root")
        if host == "generic":
            if adapter_root is not None:
                raise ValueError("generic host must not define an adapter_root")
            continue
        if not isinstance(adapter_root, str) or not adapter_root:
            raise ValueError(f"adapter_root missing for host: {host}")
        base = ROOT / adapter_root
        if not _inside(base, ROOT) or not base.is_dir():
            raise ValueError(f"adapter_root is invalid or outside package: {host}")
        # Validate only the adapter root here. Selected pointers are checked at resolution time;
        # the package validator separately audits complete adapter parity.

    return data, canonical


def resolve(
    intent: str,
    specialist_ids: list[str],
    support_ids: list[str],
    host: str = "generic",
    decision: dict[str, Any] | None = None,
    catalog_path: Path = CATALOG,
) -> dict[str, Any]:
    data, canonical = load_catalog(catalog_path)
    if intent not in data["intents"]:
        raise ValueError(f"unknown intent '{intent}'; valid: {', '.join(sorted(data['intents']))}")
    if host not in data["host_compatibility"]:
        raise ValueError(f"unknown host '{host}'; valid: {', '.join(sorted(data['host_compatibility']))}")
    if not isinstance(specialist_ids, list) or not isinstance(support_ids, list):
        raise ValueError("specialist and support selections must be lists")
    if any(not isinstance(x, str) for x in specialist_ids + support_ids):
        raise ValueError("specialist and support IDs must be strings")
    if not isinstance(decision, dict):
        raise ValueError("classification decision record is required")
    required_decision = set(data["classification_contract"]["required_decision_fields"])
    missing_fields = sorted(required_decision - set(decision))
    if missing_fields:
        raise ValueError(f"classification decision missing fields: {', '.join(missing_fields)}")
    if decision.get("dominant_intent") != intent:
        raise ValueError("classification decision dominant_intent does not match --intent")
    for field in ("primary_deliverable", "trigger_evidence", "uncertainty"):
        if not isinstance(decision.get(field), str) or not decision[field].strip():
            raise ValueError(f"classification decision field must be non-empty text: {field}")
    specialist_evidence = decision.get("specialist_evidence")
    support_evidence = decision.get("support_output_need")
    if not isinstance(specialist_evidence, dict) or set(specialist_evidence) != set(specialist_ids):
        raise ValueError("specialist_evidence keys must exactly match selected specialists")
    if not isinstance(support_evidence, dict) or set(support_evidence) != set(support_ids):
        raise ValueError("support_output_need keys must exactly match selected support skills")
    for label, evidence in (("specialist_evidence", specialist_evidence), ("support_output_need", support_evidence)):
        if any(not isinstance(value, str) or not value.strip() for value in evidence.values()):
            raise ValueError(f"{label} entries must contain non-empty evidence/reasons")
    excluded = decision.get("excluded_candidates")
    if not isinstance(excluded, list) or any(not isinstance(x, str) or not x.strip() for x in excluded):
        raise ValueError("excluded_candidates must be a list of non-empty strings (empty list is allowed)")
    if len(excluded) != len(set(excluded)):
        raise ValueError("excluded_candidates must not contain duplicates")
    selected_names = {intent, data["intents"][intent]["primary_skill"]}
    selected_names.update(data["specialists"][sid]["skill"] for sid in specialist_ids if sid in data["specialists"])
    selected_names.update(support_ids)
    contradictions = sorted(selected_names.intersection(excluded))
    if contradictions:
        raise ValueError(f"classification decision both selects and excludes: {', '.join(contradictions)}")

    specialists = sorted(set(specialist_ids))
    supports = sorted(set(support_ids))
    policy = data["resolution_policy"]
    if len(specialists) > policy["max_specialists"]:
        raise ValueError(f"too many specialists ({len(specialists)}); maximum is {policy['max_specialists']}; narrow to evidenced domains")
    if len(supports) > policy["max_support_skills"]:
        raise ValueError(f"too many support skills ({len(supports)}); maximum is {policy['max_support_skills']}; keep only distinct required outputs")

    unknown_specialists = sorted(set(specialists) - set(data["specialists"]))
    if unknown_specialists:
        raise ValueError(f"unknown specialist(s): {', '.join(unknown_specialists)}; valid: {', '.join(sorted(data['specialists']))}")
    unknown_support = sorted(set(supports) - canonical)
    if unknown_support:
        raise ValueError(f"unknown support skill(s): {', '.join(unknown_support)}; valid: {', '.join(sorted(canonical))}")

    spec = data["intents"][intent]
    host_spec = data["host_compatibility"][host]
    selected: list[dict[str, str]] = []
    suppressed: list[dict[str, str]] = []

    def add(skill: str, role: str, reason: str) -> None:
        if skill not in canonical:
            raise ValueError(f"catalog refers to missing canonical skill: {skill}")
        existing = next((item for item in selected if item["id"] == skill), None)
        if existing:
            suppressed.append({"id": skill, "requested_role": role, "winning_role": existing["role"], "reason": "same canonical skill already selected; higher-precedence role retained"})
            return
        pointer = None
        if host_spec.get("adapter_root"):
            candidate = ROOT / host_spec["adapter_root"] / skill / "SKILL.md"
            if not _inside(candidate, ROOT) or not candidate.is_file():
                raise ValueError(f"adapter pointer unavailable for selected skill: {host}/{skill}")
            pointer = candidate.relative_to(ROOT).as_posix()
        selected.append({"id": skill, "role": role, "path": f"skills/{skill}.md", "adapter_pointer": pointer, "reason": reason})

    add(spec["primary_skill"], "primary", f"Primary owner for intent '{intent}'.")
    for sid in specialists:
        item = data["specialists"][sid]
        add(item["skill"], "specialist", item["when"])
    for skill in supports:
        add(skill, "support", "Explicitly selected supporting procedure; its distinct output must be necessary.")

    if len(selected) > policy["max_unique_skills"]:
        raise ValueError(f"resolved selection has {len(selected)} unique skills; maximum is {policy['max_unique_skills']}")

    return {
        "intent": intent,
        "host": host,
        "host_status": host_spec["status"],
        "workflow": f"workflows/{spec['workflow']}.md",
        "skills": selected,
        "suppressed": suppressed,
        "classification_decision": decision,
        "policy": {
            "primary_count": 1,
            "max_specialists": policy["max_specialists"],
            "max_support_skills": policy["max_support_skills"],
            "max_unique_skills": policy["max_unique_skills"],
            "selection": "agent-classified then catalog-validated and deterministically ordered",
            "free_text_keyword_routing": False,
            "permission_grant": False,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--intent", required=True, help="One primary intent from skill-intelligence.json")
    parser.add_argument("--specialist", action="append", default=[], help="Specialist domain (repeatable; max 3)")
    parser.add_argument("--support", action="append", default=[], help="Canonical support skill ID (repeatable; max 2)")
    parser.add_argument("--host", default="generic", help="Host adapter: claude, codex or generic (discovery is not certified)")
    parser.add_argument("--decision-json", required=True, help="Auditable JSON classification rationale; see docs/CLASSIFICATION-EVALUATION.md")
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON")
    args = parser.parse_args()
    try:
        decision = json.loads(args.decision_json)
        result = resolve(args.intent, args.specialist, args.support, args.host, decision)
    except (ValueError, KeyError, json.JSONDecodeError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"Intent: {result['intent']}\nHost: {result['host']} ({result['host_status']})\nWorkflow: {result['workflow']}")
        for skill in result["skills"]:
            pointer = f" | adapter: {skill['adapter_pointer']}" if skill["adapter_pointer"] else ""
            print(f"- [{skill['role']}] {skill['id']} -> {skill['path']}{pointer}")
        for item in result["suppressed"]:
            print(f"- [suppressed] {item['id']} ({item['requested_role']} duplicate; {item['winning_role']} retained)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
