# Convergence protocol

## Cycle order

```text
intake → evidence inventory → RCA → gap analysis → applicable reviews → plan → plan re-audit
```

The first cycle establishes baseline truth. Each later cycle compares the new plan and findings with the prior cycle, checks for regressions, and records what changed.

## Severity

- `P0`: safety, security, data-loss, or feasibility blocker; cannot ship.
- `P1`: correctness, authorization, rollback, or critical reliability gap; cannot claim complete.
- `P2`: material quality or operational gap; may be accepted only with owner, rationale, and review date.
- `P3`: low-impact improvement or documentation gap; disposition explicitly.

## Stop conditions

Return `COMPLETE` only when no P0/P1 finding is open or unverified, every high-impact assumption has evidence or an explicit blocker, all acceptance criteria are testable, and every applicable review is complete or degradation-recorded.

Return `COMPLETE_WITH_RESIDUAL_RISKS` when P2/P3 items remain with an owner, rationale, verification, and review date.

Return `NEEDS_INPUT` when a user premise, authorization, or material scope choice is unresolved.

Return `BLOCKED` when external evidence, runtime access, or a security/feasibility prerequisite is unavailable after safe alternatives are exhausted.

## Anti-loop rules

- Default maximum is three full cycles; absolute maximum is five.
- A finding surviving two cycles must be escalated, not renamed or silently downgraded.
- A new P0/P1 finding resets the completion gate.
- A plan revision must never close a finding without new evidence.
- Repeated identical output is not progress; record the unchanged evidence and escalate.
