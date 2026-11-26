# Skill: use-case-analysis

## Purpose
Identify actors, derive use cases from requirements, and write user stories with
acceptance criteria — bridging the gap between business requirements and what the
solution actually needs to do.

## Trigger
Invoke when the operator says "use case analysis", "write user stories",
"what are the actors", "use cases for [feature/system]", or "break this down
into user stories".

## Minimum context required
- A project name and client
- A set of confirmed requirements (even a rough list)
If missing: run gather-requirements first, or ask for at least a scope description.

---

## Steps

1. Consult current canonical Obsidian/project memory and existing requirements/use-case records for prior analysis. Do not invoke the disabled claude-mem integration.
2. Read the project's `requirements.md` and `stakeholders.md` (actors come from
   the stakeholder register).
3. Identify **actors** — primary (directly interact with the system) and secondary
   (systems or roles the primary actor depends on).
4. For each REQ- entry, derive one or more **use cases**:
   a. Name (verb + noun: "Approve invoice", "Generate report")
   b. Primary actor
   c. Brief description (goal the actor achieves)
   d. Pre-conditions and post-conditions
   e. Main flow (numbered steps)
   f. Alternative flows / exception paths
5. **Database lens** — for every use case that reads, writes, or searches persistent data:
   - Identify which entities are created / read / updated / deleted (CRUD)
   - Flag any data consistency, concurrency, or ordering constraint
   - Note if the use case involves bulk, batch, or async operation — triggers database-admin
6. Write a **user story** per use case:
   `As a [actor], I want to [action] so that [benefit].`
   Acceptance criteria in **Given/When/Then** format:
   `Given [precondition], When [actor does action], Then [observable outcome].`
7. **INVEST check** per user story: Independent / Negotiable / Valuable / Estimable /
   Small / Testable. Flag any story that fails — explain the failing criterion and
   recommend how to fix it (split, reframe, defer).
8. Flag any use case with high complexity, multiple actors, or external system
   dependencies — these become higher-effort estimates and higher RISK.
9. Output. Wait for confirmation before writing to project files.

---

## Output format

```
USE CASE ANALYSIS: [Project Name]
Client: [name] | Date: [YYYY-MM-DD]
---

Actors:
| Actor | Type | Description | Source |
|---|---|---|---|
| [Role/system] | Primary/Secondary | [what they do] | stakeholders.md |

Use Cases:
---
UC-001: [Verb + Noun]
Actors: [Primary], [Secondary if any]
Goal: [What the actor wants to achieve]
Pre-conditions: [What must be true before this can happen]
Post-conditions: [What is true after success]

Main flow:
1. [Step]
2. [Step]

Alt flows / exceptions:
- [Condition] → [what happens]

Trace: REQ-F0X

User story:
  As a [actor], I want to [action] so that [benefit].
  Acceptance criteria (Given/When/Then):
  - Given [precondition], When [action], Then [outcome]
  - Given [edge case], When [action], Then [outcome]
  INVEST: [Independent ✓/✗] [Negotiable ✓/✗] [Valuable ✓/✗] [Estimable ✓/✗] [Small ✓/✗] [Testable ✓/✗]
  DB lens: [Entities touched] / [CRUD] / [Constraint or concurrency risk if any]

Complexity: [Low / Medium / High] — [reason if High]
---
[Repeat per use case]

Flags:
- UC-0XX: [high complexity / multiple actors / external dependency → flag for estimation and risk]

Next: confirm use cases → feed acceptance criteria into requirements.md → estimate effort
```

---

## Quality checklist

- [ ] Is every actor from stakeholders.md represented?
- [ ] Does every use case trace back to at least one REQ- entry?
- [ ] Does every user story have Given/When/Then acceptance criteria?
- [ ] Did every user story pass the INVEST check — or was the failure explained?
- [ ] Was the database lens applied to every data-touching use case?
- [ ] Are high-complexity use cases flagged for risk and estimation?
- [ ] Are external system dependencies identified?

## Failure exit
"Cannot write use cases without confirmed requirements. Run gather-requirements
first or provide a scope description to work from."
