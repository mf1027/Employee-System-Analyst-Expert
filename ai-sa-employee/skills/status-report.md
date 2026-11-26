# Skill: status-report

## Purpose
Produce a structured RAG status report for a project, ready for the operator to
review and send. Surfaces what's on track, what's at risk, what's blocked, and
what decisions or actions are needed — in the format defined in `memory/communication.md`.

## Trigger
Invoke when the operator says "status report", "write a status update",
"RAG report", "weekly update", or "draft the project report for [client]".

## Minimum context required
- A project name and client
If missing: ask which project.

---

## Steps

1. Read current canonical Obsidian/project memory and the relevant client lane — preferences,
   comms style, who the report goes to.
2. Read `memory/communication.md` — report format and RAG criteria.
3. Read the project's `plan.md` (milestones, schedule), `risks.md` (open RISK-
   entries), and `requirements.md` (scope changes).
4. Determine the **overall RAG**:
   - 🔴 Red: a milestone is missed or will be missed; a RED risk is unmitigated;
     a blocker has no resolution path.
   - 🟡 Amber: a milestone is at risk but still recoverable; a RED/AMBER risk has
     a mitigation being worked; a dependency is late.
   - 🟢 Green: on track, no blockers, no unmitigated RED risks.
5. Draft the report. Keep it factual and brief — executives read, not study.
6. Output the draft. The operator reviews and sends. Never send directly.

---

## Output format (per communication.md template)

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
| [Name] | [YYYY-MM-DD] | At risk | 🟡 | [Why at risk] |

Risks (RED and AMBER only):
| ID | Risk | RAG | Mitigation | Owner |
|---|---|---|---|---|
| RISK-00X | [Risk] | 🔴 | [Action being taken] | [Owner] |

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

---

## Save location

```
deliverables/reports/[YYYY-MM-DD]-status-report.md
```
Named by date so the full report history is readable at a glance.
Embed in the client's project folder — never committed to git (memory/clients/ is gitignored).

---

## Quality checklist

- [ ] Is the overall RAG justified by specific evidence (not just "feels amber")?
- [ ] Is the summary ≤ 3 sentences?
- [ ] Are only RED and AMBER risks surfaced (not the full register)?
- [ ] Does the report end with Decisions needed / Open questions / Next steps?
- [ ] Is the tone matched to the client's comms style from their record?
- [ ] Is this a draft — confirmed I am NOT sending it directly?

## Failure exit
"Cannot produce a status report without knowing which project. Provide the
project name and client."
