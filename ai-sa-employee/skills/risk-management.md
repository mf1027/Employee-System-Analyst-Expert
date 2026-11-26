# Skill: risk-management

## Purpose
Identify, score, and manage the full RAID log — **Risks, Assumptions, Issues,
Dependencies**. Ensures every risk has an owner, mitigation, and contingency.
RED risks trigger escalation per `memory/communication.md`. Issues are things
already going wrong; Risks are things that might go wrong.

## Trigger
Invoke when the operator says "risk management", "identify risks", "update the
RAID log", "what could go wrong", "add a risk", "log an issue", "we have a
blocker", "add a dependency", or "review the risks".

## Minimum context required
- A project name and client
If missing: ask for the project. Risk identification can start from a scope description.

---

## Steps

1. Consult current canonical Obsidian/project memory and the client lane files for prior RAID knowledge. Do not invoke the disabled claude-mem integration.
2. Read the project's `risks.md` (existing RAID log), `requirements.md`, `plan.md`,
   and `database.md` (DB-specific risks).
3. **RISKS — Identify new risks** across all categories:
   - Schedule: dependencies, resource availability, estimation confidence
   - Technical: integration complexity, new technology, vendor stability
   - People: key-person dependency, stakeholder resistance, skill gaps
   - Compliance / regulatory: data residency, audit, legal requirements
   - Database: migration locking, data loss, replication lag, schema breakage
   - Commercial: budget overrun, contract gaps, procurement delays
4. For each risk:
   a. Assign the next available `RISK-NNN` ID.
   b. Score: Probability (1–5) × Impact (1–5) = Score.
   c. RAG: 🔴 Score ≥ 16, 🟡 Score 6–15, 🟢 Score ≤ 5.
   d. Assign an **owner** (a named person or role, not "the team").
   e. Define a **trigger** — the early-warning indicator to watch.
   f. Define a **mitigation** — what to do to reduce probability/impact now.
   g. For RED risks: also define a **contingency** + escalation path
      (see `memory/communication.md` escalation rules).
5. **ASSUMPTIONS — Review and log** all assumptions in scope:
   - Assign `ASS-NNN` IDs (continue from existing entries in risks.md).
   - State: what is assumed, why, and what breaks if wrong.
   - Flag which REQ-, RISK-, or plan item each assumption affects.
6. **ISSUES — Identify active issues** (things already going wrong now):
   - Assign `ISS-NNN` IDs.
   - State: what is broken / blocked, since when, and blast radius.
   - Assign owner and target resolution date.
   - Classify: Blocker / High / Medium / Low.
   - Blockers must be escalated immediately — see `memory/communication.md`.
7. **DEPENDENCIES — Log external dependencies**:
   - Assign `DEP-NNN` IDs.
   - State: what the project depends on, owner (internal/external), and due date.
   - Flag critical-path dependencies — ones where a slip delays the project.
   - Link to the RISK- entry if a dependency slip is already scored as a risk.
8. Review existing entries — flag any RISK-/ASS-/ISS-/DEP- that are stale or resolved.
9. Output. Wait for confirmation before writing to `risks.md`.

---

## Output format

```
RAID LOG UPDATE: [Project Name]
Client: [name] | Date: [YYYY-MM-DD]
---
Context: I read [files]. Existing entries — RISK:[N] ASS:[N] ISS:[N] DEP:[N]. New entries: [N].

--- RISKS ---
| ID | Risk | Category | P | I | Score | RAG | Owner | Status |
|---|---|---|---|---|---|---|---|---|
| RISK-00X | [Risk] | [Category] | [1-5] | [1-5] | [P×I] | 🔴/🟡/🟢 | [Owner] | Open |

Risk details:
---
RISK-00X: [Risk name]
- Trigger: [what we'd observe if this is about to happen]
- Mitigation: [action to reduce P or I — who does it, by when]
- Contingency (RED only): [what we do if it materialises]
- Escalation (RED only): [per memory/communication.md escalation rules]
---

--- ASSUMPTIONS ---
| ID | Assumption | Risk if wrong | Affects | Owner |
|---|---|---|---|---|
| ASS-00X | [what is assumed] | [what breaks] | [REQ-/RISK-/plan] | [owner] |

--- ISSUES (active — things going wrong now) ---
| ID | Issue | Severity | Owner | Target Resolution | Status |
|---|---|---|---|---|---|
| ISS-00X | [what is blocked/broken] | Blocker/High/Med/Low | [owner] | [YYYY-MM-DD] | Open |

Issue details (Blockers):
---
ISS-00X: [Issue name]
- Since: [date first observed]
- Blast radius: [what else is affected if unresolved]
- Action: [immediate next step — who, by when]
- Escalation: [who to notify — per memory/communication.md]
---

--- DEPENDENCIES ---
| ID | Dependency | Type | Owner | Due | Critical Path | Linked Risk |
|---|---|---|---|---|---|---|
| DEP-00X | [what we depend on] | Internal/External | [owner] | [YYYY-MM-DD] | Yes/No | RISK-00X |

Updated/stale entries:
- [ID]: [change — e.g. risk closed, issue resolved, dependency met]

Summary:
Risks: 🔴 [N] — [IDs] | 🟡 [N] | 🟢 [N]
Issues: Blockers: [N] — [IDs] | High: [N] | Open total: [N]
Dependencies critical-path: [N] — [IDs]

Next: confirm → write to risks.md → escalate RED risks + Blockers per communication.md
```

---

## Quality checklist

- [ ] Are all six risk categories covered?
- [ ] Does every risk have an owner (named person, not "the team"), trigger, and mitigation?
- [ ] Do all RED risks have a contingency AND an escalation path?
- [ ] Are all assumptions logged with ASS- IDs and their "risk if wrong" stated?
- [ ] Are active issues logged with ISS- IDs, severity, owner, and resolution date?
- [ ] Are critical-path dependencies flagged as DEP- entries with due dates?
- [ ] Are stale/closed RAID entries flagged for update or closure?
- [ ] Are database risks reviewed — migrations, locking, data loss?

## Failure exit
"Cannot manage risks without a project to assess. Provide the project name."
