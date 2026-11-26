# Skill: stakeholder-analysis

## Purpose
Identify who is affected by or has influence over the project, map them on a
power/interest grid, build the RACI, and define a communications plan — before
decisions are made that affect them.

## Trigger
Invoke when the operator says "stakeholder analysis", "who are the stakeholders",
"build the RACI", "who do we need to consult", or "map the stakeholders".

## Minimum context required
- A project name and client
- A brief description of the project (to reason about who is affected)
If missing: ask for the project name and a one-sentence description.

---

## Steps

1. Consult current canonical Obsidian/project memory, the client lane, and existing stakeholder records for organisation context and prior stakeholder knowledge. Do not invoke claude-mem.
2. Read the project's `requirements.md` and `risks.md` — who the requirements
   mention, who owns risks.
3. Identify all stakeholder groups (individuals or roles, not just titles).
4. **Hidden stakeholder probe** — explicitly check for these groups, which are often
   missed in the first pass:
   - **Compliance / Legal**: who owns regulatory obligations for this project?
   - **IT Security**: who must approve the security architecture or data handling?
   - **Operations / Support**: who will run and maintain this after go-live?
   - **DBA / Data team**: who owns the database, schemas, and data migrations?
   - **Finance / Procurement**: who controls the budget or vendor approvals?
   - **Affected end users not in the room**: who uses the system but wasn't mentioned?
   Add any found to the stakeholder register.
5. For each stakeholder:
   a. Assess **power** (1–5): authority to approve, fund, or block the project.
   b. Assess **interest** (1–5): how much they care about the outcome.
   c. Place on the 2×2 grid and assign an engagement strategy.
6. Build the **RACI** for key decisions and deliverables.
7. Define a **comms plan**: who hears what, how often, and in what format.
8. Flag any stakeholder with high power AND potential resistance — these are the
   highest-risk relationships.
9. Output. Wait for confirmation before writing to `stakeholders.md`.

---

## Power/Interest Grid

| Quadrant | Power | Interest | Strategy |
|---|---|---|---|
| Manage closely | High | High | Involve in decisions, brief regularly |
| Keep satisfied | High | Low | Consult on impact, avoid surprises |
| Keep informed | Low | High | Include in UAT, share updates |
| Monitor | Low | Low | Minimal engagement |

---

## Output format

```
STAKEHOLDER ANALYSIS: [Project Name]
Client: [name] | Date: [YYYY-MM-DD]
---

Stakeholder Register:
| Name / Role | Group | Power | Interest | Quadrant | Engagement Strategy | Risk |
|---|---|---|---|---|---|---|
| [Sponsor] | Leadership | 5 | 5 | Manage closely | Weekly sync, cc on decisions | — |
| [End user lead] | Operations | 2 | 5 | Keep informed | UAT, biweekly updates | — |
| [IT security] | Technical | 4 | 2 | Keep satisfied | Consult on compliance req | Resistance |

High-risk relationships:
- [Stakeholder] — Reason: [high power + low alignment / resistance / unknown]

RACI:
| Decision / Deliverable | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
| Requirements sign-off | SA/PM | [Sponsor] | [Tech lead] | [End users] |
| Solution design | SA/PM | [Sponsor] | [IT security, Tech lead] | [Operations] |
| Go-live approval | SA/PM | [Sponsor] | [All] | [All] |

Comms plan:
| Audience | Frequency | Channel | Format |
|---|---|---|---|
| [Sponsor] | Weekly | Email | RAG status report |
| [End users] | At milestones | Meeting | Milestone summary |
| [IT security] | As needed | Email | Change request / impact note |

Open questions:
- [Any stakeholder whose role, power, or interest is unclear]
```

---

## Quality checklist

- [ ] Were hidden stakeholders probed — compliance, security, ops, DBA, finance, unrepresented users?
- [ ] Are ALL groups identified — not just the obvious sponsor?
- [ ] Is every stakeholder placed on the grid with an engagement strategy?
- [ ] Does the RACI cover all key decisions and deliverables?
- [ ] Are high-risk relationships (high power + potential resistance) flagged?
- [ ] Does the comms plan match the client's preferred channels from their record?

## Failure exit
"Cannot map stakeholders without a project description. Provide the project name
and a brief description of what it does and who it affects."
