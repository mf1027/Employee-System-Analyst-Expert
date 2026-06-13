# Skill: solution-design

## Purpose
Design the solution at a conceptual and logical level — components, interfaces,
integration points, and data flows — and record key decisions as ADRs. Produces
a solution that satisfies confirmed requirements, not one invented before them.

## Trigger
Invoke when the operator says "design the solution", "architecture", "how should
we build this", "solution options", or "what's the technical approach".

## Minimum context required
- Confirmed requirements (requirements.md with at least P0 items signed off)
- The client / project
If missing: run gather-requirements first.

---

## Steps

1. Read `memory/memory.md` and `memory/clients/[client-name].md`. Search claude-mem:
   `mem search "[project] design decisions"` to retrieve prior architecture knowledge.
2. Read the project's `requirements.md` (confirmed P0 scope), `stakeholders.md`
   (constraints, non-functional expectations), `risks.md`, and `database.md`.
3. **NFR → design mapping** — extract all `REQ-NF` entries from `requirements.md`.
   For each **design-forcing NFR** (flagged by nfr-review):
   - State which architecture decision it constrains.
   - If any design option would violate a design-forcing NFR, that option is eliminated.
   - Document the constraint as a given in the relevant ADR.
4. Identify the **key design decisions** — the choices that, once made, constrain
   everything else.
5. For each key decision: generate 2–3 options, evaluate against requirements and
   constraints, and recommend one. Document as an ADR.
6. Use the **C4 model** to structure the design output (if architecture scope):
   - **C4 L1 (Context):** what is the system and who uses it?
   - **C4 L2 (Containers):** what are the deployable parts + tech stack?
   - Only go to L3 (Components) for complex or disputed boundaries.
   - Chain to `create-diagram` for Mermaid rendering.
7. Draw the **solution components**: the logical building blocks and how they interact.
8. Map **interfaces and integration points**: what connects to what, data flowing
   each way, and who owns each connection.
9. Apply the **database lens** proactively:
   - Does any component own or mutate persistent data?
   - Are there schema changes? Migration risk?
   - Is there a reporting/read requirement that needs a separate pattern?
   - Flag anything into the project's `database.md`.
10. **API contract review (Postman).** If the design includes external APIs or the
    client has existing API collections: use Postman MCP (`mcp__claude_ai_Postman__getCollections`,
    `mcp__claude_ai_Postman__getSpec`) to retrieve and validate interface contracts.
    Flag spec gaps or mismatches as open design questions.
11. Flag open design questions and assumptions.
12. Output. Wait for confirmation before writing to `decisions.md` or `database.md`.

---

## Output format

```
SOLUTION DESIGN: [Project Name]
Client: [name] | Date: [YYYY-MM-DD]
---
Context: Requirements read — [N] P0 items confirmed. Key constraints: [list].
NFR design-forcing: [list REQ-NF entries that constrain architecture choices]

Architecture style: [e.g. service-oriented, monolith, event-driven]
Rationale: [why this style fits the constraints and scale]

Key design decisions:
---
ADR-001: [Decision title]
Context: [Why a choice was needed]
Options:
  A. [Option] — Pros: [list] | Cons: [list]
  B. [Option] — Pros: [list] | Cons: [list]
Recommendation: [Option A/B] — because [specific reason tied to requirements]
Consequences: [What this rules out or enables]
---

Solution components:
| Component | Responsibility | Owner | Interfaces with |
|---|---|---|---|
| [Name] | [What it does] | [Role/team] | [Other component] |

Integration points:
| Integration | Direction | Data | Protocol / method | Owner | Risk |
|---|---|---|---|---|---|
| [System A → B] | Async/Sync | [what flows] | [API/event/DB] | [team] | [Low/Med/High] |

Database lens:
- [Component] owns [entity] — migration needed: [Yes/No] — flagged in database.md
- [Any read-heavy query pattern that needs an index or read replica]

Open design questions:
1. [Question] — blocks ADR-00X if unresolved
2. ...

Flags for risks.md:
- RISK-XXX: [design risk — e.g. vendor API not production-ready]

Next: confirm design → write ADRs to decisions.md → update database.md
```

---

## Quality checklist

- [ ] Were design-forcing NFRs mapped before options were evaluated?
- [ ] Does every ADR cover all options considered, not just the winner?
- [ ] Is the architecture style named and justified against requirements?
- [ ] Are C4 L1 and L2 diagrams produced — or explicitly deferred?
- [ ] Are all integration points identified with data direction and ownership?
- [ ] Has the database lens been applied — every data-owning component flagged?
- [ ] Are open design questions explicit, not buried?
- [ ] Are new risks flagged for `risks.md`?

## Failure exit
"Cannot design without confirmed requirements. Gather and sign off requirements first."
