# Skill: plan-project

## Purpose
Build a structured project plan — phases, milestones, WBS, schedule, critical path,
and resource needs — before any delivery work begins. Produces a plan grounded in
confirmed requirements and known risks, not assumptions.

## Trigger
Invoke when the operator says "build the plan", "create the project plan",
"what's the timeline", "build the WBS", or "how do we structure this project".

## Minimum context required
- A project name and client
- At least a rough scope or requirements baseline
If missing: ask for the project name and a one-line scope summary.

---

## Steps

1. Review current canonical Obsidian/project memory and the client lane for constraints (deadlines, budget, resource limits) and prior planning decisions. Do not invoke claude-mem.
2. Read the project's `requirements.md` (scope baseline), `risks.md` (known risks
   that affect the schedule), and `database.md` (any DB migration work in scope).
3. Output a **CONTEXT SUMMARY** — what I read, key constraints, confidence level.
4. **Confirm scope baseline** — if requirements are still `[TBC]`, flag it and
   ask the operator to confirm scope before planning. Never plan against assumed scope.
5. Build the **WBS** — decompose into phases, then work packages, then estimable tasks.
6. Sequence with dependencies; identify the **critical path**.
7. Estimate each work package using three-point (Optimistic / Most Likely / Pessimistic)
   and calculate PERT estimates.
8. Set **milestones** tied to deliverables, not just dates.
9. Flag what could blow the plan — feed into `risks.md` as new `RISK-` entries.
10. Output the plan. Wait for confirmation before writing to `plan.md`.

---

## Output format

```
PROJECT PLAN: [Project Name]
Client: [name] | Date: [YYYY-MM-DD]
---
Context: I read [files]. Confidence: [level] because [reason].

Phases & Milestones:
| Phase | Milestone | Target Date | Dependencies | Status |
|---|---|---|---|---|
| Discovery | Requirements sign-off | [date] | — | Pending |
| Design | Solution design approved | [date] | M1 | Pending |
| Delivery | MVP ready for UAT | [date] | M2 | Pending |
| Go-live | Production deployment | [date] | M3 | Pending |

WBS:
1. Discovery (Est: [X] days)
   1.1 Stakeholder interviews ([X]d)
   1.2 Requirements elicitation ([X]d)
   1.3 Requirements sign-off ([X]d)
2. Design (Est: [X] days)
   ...

Critical Path: [Phase A → Milestone B → Phase C → Go-live]
  Note: [what gates the critical path — e.g. "vendor API blocks Design phase"]

Estimates:
| Work package | O | ML | P | PERT | Confidence |
|---|---|---|---|---|---|
| [Package] | [Xd] | [Xd] | [Xd] | [Xd] | High/Med/Low |

Total estimate: [X–Y days] | Confidence: [level]

Risks to plan:
- RISK-XXX: [risk that affects this plan — flag for RAID log]

Next steps: confirm plan → write to plan.md → open RISK- entries for plan risks
```

---

## Quality checklist

- [ ] Is scope confirmed before planning? (No planning against `[TBC]` requirements)
- [ ] Does the WBS decompose to estimable work packages (not just phase names)?
- [ ] Is the critical path identified and named?
- [ ] Are estimates three-point, not single-point?
- [ ] Are milestones tied to deliverables, not just calendar dates?
- [ ] Are dependencies between phases explicit?
- [ ] Are new RISK- entries flagged for addition to `risks.md`?
- [ ] Does the plan account for any database migration work in `database.md`?

## Failure exit
"Cannot plan without a confirmed scope. Gather requirements first or provide a
scope summary to plan against."
