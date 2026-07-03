# Skill: developer-handoff

## Purpose
Package finished analysis and design into **implementation-ready work** the developer can pick
up without re-deriving anything. This is the missing bridge: we produce requirements, an SRS,
an architecture, a schema — and then the developer (often the operator himself) has to manually
translate all of it into tickets, sequence them, and guess the acceptance criteria. That manual
translation is where scope drifts and detail is lost. This skill makes the handoff a deliverable,
not an act of telepathy.

The employee does **not** write application code (per the operating manual). It produces the
spec the coder builds from — tickets, acceptance criteria, technical notes, dependency order —
and stops at the code boundary.

## Trigger
Invoke when the operator says "hand this off to the developer", "make dev tickets", "turn this
into tasks for coding", "what does the developer need", "implementation spec", "ready for dev",
"gawing dev tasks". Also a natural chain after DESIGN/PLAN mode produces a locked design.

**Module delivery pack (WFC-005, observed 6× across MYPS 2026-07-01/02):** for each dev-ready
module, this skill is step one of a chain — `developer-handoff` → `test-strategy` → an FE/BE
task-breakdown pass (discipline sub-tasks with estimates + deps) → a user-level manual QA test
plan → cards on the project `board.md`. Run the whole chain per module rather than one step across
all modules — it lets you checkpoint accumulated decisions before the next, more delicate module.
Two things that made this repeat cleanly: sync every consumer doc (register, risks, decisions) in
the *same* pass per module, not batched at the end; and give any service shared across modules
(an ID generator, a validator, a rule engine) exactly one owning module so the others just consume it.

## Minimum context required
- A confirmed requirement set (`REQ-` IDs) and/or a locked design (`ADR-`s, schema, architecture).
- The target stack (so technical notes are concrete, not generic).
- If requirements or design are still open → say so and handle the open items first; don't hand
  off a moving target.

---

## What a good handoff contains

Each work item is a ticket with everything the developer needs and nothing they must chase:

| Field | Why it's there |
|---|---|
| **ID + title** | Traceable (`DEV-NNN`), scannable |
| **Traces to** | The `REQ-`/`ADR-` it implements — two-way traceability back to the spec |
| **Description** | What to build, in one tight paragraph — the *what* and *why*, not the *how* |
| **Acceptance criteria** | Given/When/Then, testable — the definition of done for this ticket |
| **Technical notes** | Stack-specific guidance: endpoints, schema tables/columns, libraries, patterns to follow |
| **Edge cases** | The shadow paths: empty, max, error, concurrency, permission — named, not left to chance |
| **Dependencies** | Which `DEV-` items must land first (build order) |
| **Estimate** | Three-point (O/M/P) or t-shirt — with the uncertainty stated |
| **Out of scope** | What this ticket explicitly does *not* cover — the #1 scope-creep guard |

---

## Steps
1. Confirm the source is locked (requirements confirmed, design has ADRs). If not, stop and close
   the open items first.
2. Decompose the design into vertical slices — each ticket should deliver a testable increment,
   not a horizontal layer ("build all the DB tables") that can't be demoed.
3. For each slice, write the ticket with every field above. Pull acceptance criteria straight from
   the `REQ-` criteria where they exist — don't reinvent them.
4. **Sequence** the tickets by dependency; mark the critical path. Call out what can be parallelized.
5. Apply the **triple lens**: SA (does every REQ map to a ticket — coverage check?), PM (is the
   build order and estimate realistic?), DBA (do tickets touching data carry the right schema notes
   and migration order?).
6. Surface at least one `REC-` (e.g. a slice that should be a spike first, or a risky dependency).
7. Write the handoff pack to `memory/clients/[client]/[project]/deliverables/documents/` and update
   `tasks.md`/`plan.md` with the `DEV-` IDs.

---

## Output format
```
DEVELOPER HANDOFF — [project] — [YYYY-MM-DD]
Stack: [target stack]   Source: [REQ set / design version]

COVERAGE CHECK
  [N] requirements → [N] tickets   (every REQ- maps to ≥1 DEV- · gaps: none / listed)

DEV-001 — [title]                                    Est: [O/M/P]   Critical path: yes/no
  Traces to:   REQ-F03, ADR-018
  Description: [what + why, one paragraph]
  Acceptance:  Given … When … Then …
  Tech notes:  [tables/columns, endpoints, libs, patterns]
  Edge cases:  [empty / max / error / concurrency / permission]
  Depends on:  [DEV-… or "nothing"]
  Out of scope:[explicit exclusions]

[… more tickets …]

BUILD ORDER
  Critical path: DEV-001 → DEV-004 → DEV-007
  Parallelizable: {DEV-002, DEV-003} after DEV-001

REC-NNN: [the one thing the developer should know that wasn't asked]
```

Close with **Decisions needed / Open questions / Next steps**.

## Quality checklist
- [ ] Every `REQ-` traces to at least one ticket (coverage check shown, gaps named)
- [ ] Every ticket has testable acceptance criteria and an explicit out-of-scope line
- [ ] Build order has a marked critical path; parallel work identified
- [ ] Tickets are vertical slices (demoable), not horizontal layers
- [ ] DBA lens applied to every data-touching ticket (schema notes + migration order)
- [ ] `DEV-` IDs written to `tasks.md`; at least one `REC-` surfaced
- [ ] No application code written — spec only, stops at the code boundary

## Failure exit
"Source isn't locked yet — [requirements still open / design has no ADRs]. A handoff built on a
moving target just moves the rework downstream. Let's close [the open items] first, then I'll
package the tickets."
