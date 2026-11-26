# Skill: gather-requirements

## Purpose
Elicit, structure, and document requirements using REQ- IDs, priority levels,
and acceptance criteria. Ensures each requirement captures a need — not a solution —
and is traceable from source to acceptance.

## Trigger
Invoke when the operator says "gather requirements", "document requirements",
"what do they need", "write up the requirements", or "let's do requirements".

## Minimum context required
- A project name and client
- Either a brief description of the problem or a stakeholder to interview
If missing: ask for the project and what they're trying to solve.

---

## Steps

1. Consult current canonical Obsidian/project memory, the client lane, and existing requirements/glossary records before starting. Do not invoke the disabled claude-mem integration.
2. **Read before you ask — hard gate.** Read ALL available existing documentation before
   starting interrogation: `requirements.md`, `decisions.md`, meeting notes, and any files in
   `reference/`. Evidence-first principle: quote what you found, identify what is missing, then
   ask only about the gaps. Never interrogate from scratch when context already exists.
2.5 **5W framing — apply before writing any requirement:**
   1. **Who** — which role, persona, or system is affected?
   2. **What (current)** — what is the actual current behaviour or gap? (verified, not assumed)
   3. **What (target)** — what should it do instead?
   4. **Why now** — what is currently blocked, broken, or costing the business?
   5. **How verified** — what observable, measurable outcome confirms it is done?
   If any of the 5 answers are unknown → flag as an open question. Do not write the requirement yet.

3. For each requirement:
   a. Confirm it expresses a **need**, not a solution. If it prescribes HOW, rephrase
      it as a what/why and note the proposed solution separately.
   b. Assign a REQ-F ID (next available functional number).
   c. Assign a priority: P0 (Must Have), P1 (Should Have), P2 (Nice to Have).
   d. Write at least one acceptance criterion in **Given/When/Then** format:
      `Given [precondition], When [actor does action], Then [observable outcome].`
   e. Note the source stakeholder.
   f. Probe the **shadow paths**: empty input, max input, error/failure case,
      concurrency, permissions edge case — add as additional acceptance criteria.
4. **NFR pass** — after functional requirements, explicitly ask about: performance targets,
   security/compliance, availability SLA, scalability, and database implications.
   Assign `REQ-NF` IDs. For a full NFR pass, invoke `nfr-review`.
5. Flag any requirement that **conflicts with, duplicates, or is dependent on** another —
   note the conflict inline with both REQ- IDs.
6. Log all **assumptions** with `ASS-` IDs (next available from `risks.md` Assumptions section).
7. List open questions that would block or change requirements if unresolved.
8. Output the structured requirements. Wait for confirmation before writing to `requirements.md`.

---

## Output format

```
REQUIREMENTS: [Project Name]
Client: [name] | Date: [YYYY-MM-DD]
---
Context: I read [files]. Domain: [relevant context]. Glossary terms applied: [list].

Functional Requirements:
| ID | Requirement | Priority | Acceptance Criteria (Given/When/Then) | Source | Conflicts/Deps |
|---|---|---|---|---|---|
| REQ-F01 | [As a [role], I need [outcome] so that [benefit]] | P0 | Given [state], When [action], Then [outcome] | [Stakeholder] | — |
| REQ-F02 | ... | P1 | | | |

Non-Functional Requirements:
| ID | Type | Requirement | Target | Notes |
|---|---|---|---|---|
| REQ-NF01 | Performance | [NFR description] | [Measurable target — no vague adjectives] | |
| REQ-NF02 | Security | | | |

Shadow paths checked per requirement:
- REQ-F01: empty input → [behaviour]; max input → [behaviour]; error case → [behaviour]

Out of scope (explicitly):
- [Item] — Reason: [why it was excluded]

Open questions:
1. [Question] — blocking REQ-F0X if unresolved

Assumptions (ASS- IDs):
| ID | Assumption | Risk if wrong | Affects |
|---|---|---|---|
| ASS-001 | [Assumption] | [What breaks] | REQ-F0X |

Next: confirm requirements → write to requirements.md → stakeholder sign-off → run nfr-review for full NFR pass
```

---

## Quality checklist

- [ ] Does every functional requirement state a need, not a solution?
- [ ] Does every requirement have a REQ- ID, priority, and Given/When/Then acceptance criterion?
- [ ] Are shadow paths (empty/max/error/concurrency) probed for each requirement?
- [ ] Are conflicting or duplicate requirements flagged with both REQ- IDs?
- [ ] Are out-of-scope items explicitly listed?
- [ ] Are open questions and assumptions captured with ASS- IDs?
- [ ] Is the source stakeholder named for each requirement?
- [ ] Was the 5W framework applied before writing each requirement (Who / What current / What target / Why now / How verified)?
- [ ] Were existing documents read BEFORE interrogation — or was interrogation started from scratch?
- [ ] Were NFRs covered — or nfr-review flagged to run next?

## Failure exit
"Cannot gather requirements without a project and problem description. Provide the
project name and either the stakeholder to interview or a brief scope description."
