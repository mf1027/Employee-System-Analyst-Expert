# Evidence bundle schema v2

`run.json` is the machine-readable source of truth for a bundle-mode run. Markdown artifacts are the human-readable presentation.

## Run contract

```json
{
  "schemaVersion": "2.0",
  "skill": "plan-analysis",
  "runId": "revision-type-display",
  "mode": "BUNDLE",
  "persistence": "CLIENT_BUNDLE",
  "client": {
    "name": "myps",
    "project": "myps-system",
    "artifactPath": "memory/clients/myps/myps-system/deliverables/documents/plan-analysis/revision-type-display"
  },
  "startedAt": "2026-09-14T10:00:00Z",
  "completedAt": "2026-09-14T10:15:00Z",
  "status": "COMPLETE",
  "cycleTarget": 3,
  "maxCycles": 5,
  "cycles": [
    {
      "number": 1,
      "status": "COMPLETE",
      "changeSummary": "Baseline evidence and plan established.",
      "findingIds": [],
      "phases": {
        "intake": {"status": "COMPLETE", "evidenceRefs": ["rca.md#evidence-register"]},
        "rca": {"status": "COMPLETE", "evidenceRefs": ["rca.md#root-cause-register"]},
        "gapAnalysis": {"status": "COMPLETE", "evidenceRefs": ["gap-analysis.md#gap-register"]},
        "review": {"status": "COMPLETE", "evidenceRefs": ["review-ledger.md#review-coverage"]},
        "plan": {"status": "COMPLETE", "evidenceRefs": ["plan.md#recommended-approach"]},
        "reAudit": {"status": "COMPLETE", "evidenceRefs": ["review-ledger.md#decision-audit-trail"]}
      }
    },
    {
      "number": 2,
      "status": "COMPLETE",
      "changeSummary": "Independent challenge closed the identified gaps.",
      "findingIds": [],
      "phases": {
        "intake": {"status": "COMPLETE", "evidenceRefs": ["rca.md#evidence-register"]},
        "rca": {"status": "COMPLETE", "evidenceRefs": ["rca.md#root-cause-register"]},
        "gapAnalysis": {"status": "COMPLETE", "evidenceRefs": ["gap-analysis.md#gap-register"]},
        "review": {"status": "COMPLETE", "evidenceRefs": ["review-ledger.md#review-coverage"]},
        "plan": {"status": "COMPLETE", "evidenceRefs": ["plan.md#recommended-approach"]},
        "reAudit": {"status": "COMPLETE", "evidenceRefs": ["review-ledger.md#decision-audit-trail"]}
      }
    },
    {
      "number": 3,
      "status": "COMPLETE",
      "changeSummary": "Final re-audit verified convergence.",
      "findingIds": [],
      "phases": {
        "intake": {"status": "COMPLETE", "evidenceRefs": ["rca.md#evidence-register"]},
        "rca": {"status": "COMPLETE", "evidenceRefs": ["rca.md#root-cause-register"]},
        "gapAnalysis": {"status": "COMPLETE", "evidenceRefs": ["gap-analysis.md#gap-register"]},
        "review": {"status": "COMPLETE", "evidenceRefs": ["review-ledger.md#review-coverage"]},
        "plan": {"status": "COMPLETE", "evidenceRefs": ["plan.md#recommended-approach"]},
        "reAudit": {"status": "COMPLETE", "evidenceRefs": ["review-ledger.md#decision-audit-trail"]}
      }
    }
  ],
  "findings": [],
  "reviews": [
    {"id": "REV-PRODUCT", "area": "PRODUCT", "applicable": true, "method": "INTERNAL", "adapter": "INTERNAL_CHECKLIST", "status": "COMPLETED", "reason": "Premises reviewed.", "outcome": "No premise changes required.", "findingIds": [], "degradationIds": []},
    {"id": "REV-DESIGN", "area": "DESIGN", "applicable": false, "method": "INTERNAL", "adapter": "INTERNAL_CHECKLIST", "status": "NOT_APPLICABLE", "reason": "No UI surface.", "outcome": "No design review was needed.", "findingIds": [], "degradationIds": []},
    {"id": "REV-ENGINEERING", "area": "ENGINEERING", "applicable": true, "method": "INTERNAL", "adapter": "INTERNAL_CHECKLIST", "status": "COMPLETED", "reason": "Failure controls reviewed.", "outcome": "Controls and tests are sufficient.", "findingIds": [], "degradationIds": []},
    {"id": "REV-DX", "area": "DX", "applicable": false, "method": "INTERNAL", "adapter": "INTERNAL_CHECKLIST", "status": "NOT_APPLICABLE", "reason": "No developer-facing surface.", "outcome": "No DX review was needed.", "findingIds": [], "degradationIds": []}
  ],
  "degradations": [],
  "acceptanceCriteria": [
    {"id": "AC-001", "statement": "The plan is testable.", "verification": "Run the documented test matrix.", "status": "VERIFIED"}
  ],
  "residualRisks": [],
  "decisions": [
    {"id": "DEC-001", "phase": "PLAN", "decision": "Use the recommended approach.", "classification": "MECHANICAL", "rationale": "It is supported by the evidence."}
  ]
}
```

## Required fields

- `mode` is `LIVE` or `BUNDLE`; persisted folders use `BUNDLE` with `persistence: CLIENT_BUNDLE`.
- `persistence` is `CHAT_ONLY` or `CLIENT_BUNDLE`. A `CLIENT_BUNDLE` requires `client.name`, `client.project`, and an `artifactPath` exactly matching the approved client-deliverables location; the validator also requires the bundle directory itself to match that path under the agent root.
- `cycleTarget` defaults to `3`; a different target requires `cycleTargetOverrideReason`. `maxCycles` is no greater than `5`, and a terminal result needs at least `cycleTarget` complete cycles. Each item in `cycles` represents one complete pass, not one phase.
- Every cycle contains the six `phases`: `intake`, `rca`, `gapAnalysis`, `review`, `plan`, and `reAudit`. Each phase has `COMPLETE`, `DEGRADED`, or `BLOCKED` status and non-empty evidence references. Each reference uses `<artifact>.md#<heading-anchor>` and must resolve to a heading in one of the bundle's Markdown artifacts.
- Artifact IDs use uppercase hyphenated segments, such as `GAP-001`, `REV-ENGINEERING`, and `DEC-001`. Each finding has `id`, `kind`, `severity`, `classification`, `statement`, `evidenceRefs`, `status`, `owner`, `disposition`, and `verification`; its evidence references must resolve to bundle Markdown headings.
- `reviews` contains an `INTERNAL` entry for each `PRODUCT`, `DESIGN`, `ENGINEERING`, and `DX` lens. Every entry records `adapter`, `applicable`, `method`, `status`, reason, outcome, and related finding IDs. Internal reviews use `adapter: INTERNAL_CHECKLIST`. A GSTACK entry uses one approved `gstack-*` adapter plus `operatorOptIn: true` and `sideEffectWarningAcknowledged: true`.
- A `DEGRADED` review references one or more items in `degradations`; each degradation has `id`, `capability`, `reason`, `impact`, and `mitigation`. Review evidence references must resolve to bundle Markdown headings.
- Each acceptance criterion has `id`, `statement`, `verification`, and `status` (`VERIFIED`, `PENDING`, or `BLOCKED`).
- Each residual risk identifies a P2/P3 finding and records an owner, rationale, verification, and ISO-8601 review date.

## Completion rules

`COMPLETE` requires at least the target number of complete cycles, a completed final re-audit, resolved or explicitly out-of-scope P0/P1 findings and high-impact assumptions, verified acceptance criteria, completed or degraded applicable review lenses, and no residual risks.

`COMPLETE_WITH_RESIDUAL_RISKS` requires the same critical controls plus a residual-risk record for every unresolved P2/P3 finding. `NEEDS_INPUT` and `BLOCKED` still require structurally valid evidence and explicit reasons.

## Required Markdown headings

- `plan.md`: `## Problem`, `## Recommended Approach`, `## Acceptance Criteria`, `## Rollout and Monitoring`, `## Rollback`, `## Explicit Non-Scope`.
- `rca.md`: `## Evidence Register`, `## Root Cause Register`.
- `gap-analysis.md`: `## Gap Register`.
- `review-ledger.md`: `## Review Coverage`, `## Adapter Runs`, `## Degradation Register`, `## Decision Audit Trail`.
- `test-rollout.md`: `## Test Matrix`, `## Release Gates`.
