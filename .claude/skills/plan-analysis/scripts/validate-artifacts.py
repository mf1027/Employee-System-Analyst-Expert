#!/usr/bin/env python3
"""Validate a plan-analysis evidence bundle using only the Python standard library."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REQUIRED = ("plan.md", "rca.md", "gap-analysis.md", "review-ledger.md", "test-rollout.md", "run.json")
STATUSES = {"COMPLETE", "COMPLETE_WITH_RESIDUAL_RISKS", "NEEDS_INPUT", "BLOCKED"}
FINDING_STATUSES = {"OPEN", "CLOSED", "ACCEPTED", "BLOCKED", "OUT_OF_SCOPE"}
SEVERITIES = {"P0", "P1", "P2", "P3"}
SECRET_PATTERNS = (
    re.compile(r"(?i)(?:api[_-]?key|access[_-]?token|client[_-]?secret|password|private[_-]?key)\s*[:=]\s*[A-Za-z0-9+/=_-]{12,}"),
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
)
HEADINGS = {
    "plan.md": ("## Problem", "## Recommended Approach", "## Acceptance Criteria", "## Rollout and Monitoring", "## Rollback", "## Explicit Non-Scope"),
    "rca.md": ("## Evidence Register", "## Root Cause Register"),
    "gap-analysis.md": ("## Gap Register",),
    "review-ledger.md": ("## Review Coverage", "## Decision Audit Trail"),
    "test-rollout.md": ("## Test Matrix", "## Release Gates"),
}


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate-artifacts.py <bundle-directory>", file=sys.stderr)
        return 2
    root = Path(sys.argv[1]).resolve()
    errors: list[str] = []
    if not root.is_dir():
        print(f"ERROR: bundle directory not found: {root}", file=sys.stderr)
        return 2
    for name in REQUIRED:
        if not (root / name).is_file():
            errors.append(f"missing required artifact: {name}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    try:
        run = json.loads((root / "run.json").read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"run.json is not valid UTF-8 JSON: {exc}")
        run = {}
    if run.get("schemaVersion") != "1.0":
        errors.append("run.json schemaVersion must be 1.0")
    if run.get("skill") != "plan-analysis":
        errors.append("run.json skill must be plan-analysis")
    if run.get("status") not in STATUSES:
        errors.append("run.json has an invalid completion status")
    cycles = run.get("cycles")
    if not isinstance(cycles, list) or not cycles:
        errors.append("run.json cycles must be a non-empty list")
    else:
        try:
            max_cycles = int(run.get("maxCycles", 5))
        except (TypeError, ValueError):
            max_cycles = 5
            errors.append("run.json maxCycles must be an integer")
        if len(cycles) > max_cycles or len(cycles) > 5:
            errors.append("cycle count exceeds the configured or absolute maximum of five")

    findings = run.get("findings", [])
    if not isinstance(findings, list):
        errors.append("run.json findings must be a list")
        findings = []
    ids: set[str] = set()
    for index, finding in enumerate(findings, 1):
        if not isinstance(finding, dict):
            errors.append(f"finding {index} is not an object")
            continue
        finding_id = finding.get("id")
        if not finding_id or finding_id in ids:
            errors.append(f"finding {index} has a missing or duplicate id")
        ids.add(str(finding_id))
        if finding.get("severity") not in SEVERITIES:
            errors.append(f"finding {finding_id} has invalid severity")
        if finding.get("status") not in FINDING_STATUSES:
            errors.append(f"finding {finding_id} has invalid status")
        if finding.get("status") == "CLOSED" and not finding.get("evidenceRefs"):
            errors.append(f"closed finding {finding_id} must include evidenceRefs")
        if finding.get("status") in {"ACCEPTED", "BLOCKED"} and not finding.get("owner"):
            errors.append(f"accepted/blocked finding {finding_id} must include an owner")
        if finding.get("status") in {"ACCEPTED", "BLOCKED", "OUT_OF_SCOPE"} and not finding.get("disposition"):
            errors.append(f"finding {finding_id} needs a disposition")
        if not finding.get("verification"):
            errors.append(f"finding {finding_id} needs verification")

    if run.get("status") == "COMPLETE" and any(
        isinstance(f, dict) and f.get("severity") in {"P0", "P1"} and f.get("status") not in {"CLOSED", "OUT_OF_SCOPE"}
        for f in findings
    ):
        errors.append("COMPLETE requires every P0/P1 finding to be closed or explicitly out of scope")

    for name, headings in HEADINGS.items():
        text = (root / name).read_text(encoding="utf-8")
        for heading in headings:
            if heading not in text:
                errors.append(f"{name} is missing required heading: {heading}")
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                errors.append(f"possible secret detected in {name}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"PASS: plan-analysis bundle is valid ({root})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
