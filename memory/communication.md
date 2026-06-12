# Communication Standards

## RAG Criteria

| Colour | When to apply |
|---|---|
| 🔴 Red | Milestone missed or will be missed; RED risk unmitigated; blocker has no resolution path |
| 🟡 Amber | Milestone at risk but recoverable; RED/AMBER risk has mitigation in progress; dependency late |
| 🟢 Green | On track; no blockers; no unmitigated RED risks |

## Status Report Template

```
PROJECT STATUS: [Project Name]
Client: [name] | Period: [YYYY-MM-DD to YYYY-MM-DD] | Prepared: [YYYY-MM-DD]
---
Overall status: 🔴 RED / 🟡 AMBER / 🟢 GREEN

Summary (2–3 sentences max):
[What happened this period, headline result, headline concern if any]

Milestones:
| Milestone | Target | Status | RAG | Notes |
|---|---|---|---|---|
| [Name] | [YYYY-MM-DD] | On track / At risk / Complete / Missed | 🟢 | |

Risks (RED and AMBER only):
| ID | Risk | RAG | Mitigation | Owner |
|---|---|---|---|---|
| RISK-00X | [Risk] | 🔴 | [Action in progress] | [Owner] |

Completed this period:
- [What was finished]

In progress:
- [What is being worked]

Blocked:
- [What is blocked and why]

---
Decisions needed:
- [What the reader needs to decide, with a deadline if applicable]

Open questions:
- [Unresolved items that could affect direction]

Next steps:
- [What happens next, owned by whom]
```

## Escalation Rules

| Trigger | Action | Timeframe |
|---|---|---|
| RED risk with no mitigation | Escalate to project sponsor | Within 24h |
| Missed milestone | Flag in status report immediately | Don't wait for scheduled report |
| Blocker with no owner | Assign owner before session ends | Same session |
| Scope change requested | Invoke change-management skill | Before accepting |

## Tone Defaults

- Plain English; no jargon unless the client uses it themselves
- Executive-facing outputs: metric/fact before narrative
- Client-facing messages: 50–100 words, conclusion first
- Tone matched to each client's comms style (see `memory/clients/[name].md`)

## ID Reference

| ID format | Meaning | Created by |
|---|---|---|
| REQ-FNN | Functional requirement | gather-requirements |
| REQ-NFNN | Non-functional requirement | gather-requirements / nfr-review |
| RISK-NNN | Risk | risk-management |
| ASS-NNN | Assumption | gather-requirements / risk-management |
| ISS-NNN | Issue (active problem with impact now) | risk-management |
| DEP-NNN | Dependency on external party/event | risk-management |
| CR-NNN | Change request | change-management |
| ADR-NNN | Architecture Decision Record | solution-design |
| UC-NNN | Use case | use-case-analysis |
| REC-NNN | Recommendation | any skill |
| KB-NNN | Knowledge base entry (claude-mem) | ingest-reference |
