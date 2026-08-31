# Evidence bundle schema

`run.json` is the machine-readable source of truth for a plan-analysis run. Markdown artifacts are the human-readable presentation.

```json
{
  "schemaVersion": "1.0",
  "skill": "plan-analysis",
  "runId": "stable-run-id",
  "startedAt": "ISO-8601",
  "completedAt": "ISO-8601 or null",
  "status": "COMPLETE|COMPLETE_WITH_RESIDUAL_RISKS|NEEDS_INPUT|BLOCKED",
  "maxCycles": 5,
  "cycles": [
    {"number": 1, "kind": "RCA|GAP|PLAN|REAUDIT", "status": "COMPLETE", "findingIds": []}
  ],
  "findings": [
    {
      "id": "RCA-001",
      "kind": "root_cause|gap|assumption|blocker",
      "severity": "P0|P1|P2|P3",
      "classification": "SYMPTOM|ROOT_CAUSE_CONFIRMED|ROOT_CAUSE_PROBABLE|CONTRIBUTING_FACTOR|ASSUMPTION|EXTERNAL_BLOCKER",
      "statement": " concise finding ",
      "evidenceRefs": ["rca.md#RCA-001"],
      "status": "OPEN|CLOSED|ACCEPTED|BLOCKED|OUT_OF_SCOPE",
      "owner": "team or role",
      "disposition": "why this state is valid",
      "verification": "test or evidence required"
    }
  ],
  "decisions": [{"id": "DEC-001", "phase": "CEO|DESIGN|ENG|DX|REAUDIT", "decision": "...", "classification": "MECHANICAL|TASTE|USER_CHALLENGE", "rationale": "..."}],
  "reviews": [{"name": "plan-eng-review", "status": "COMPLETED|FALLBACK|UNAVAILABLE", "findings": 0}],
  "degradation": [{"capability": "web-search", "status": "UNAVAILABLE", "impact": "..."}],
  "residualRisks": [{"findingId": "GAP-002", "owner": "...", "reviewDate": "ISO-8601", "acceptance": "..."}]
}
```

Required Markdown headings:

- `plan.md`: `## Problem`, `## Recommended Approach`, `## Acceptance Criteria`, `## Rollout and Monitoring`, `## Rollback`, `## Explicit Non-Scope`.
- `rca.md`: `## Evidence Register`, `## Root Cause Register`.
- `gap-analysis.md`: `## Gap Register`.
- `review-ledger.md`: `## Review Coverage`, `## Decision Audit Trail`.
- `test-rollout.md`: `## Test Matrix`, `## Release Gates`.
