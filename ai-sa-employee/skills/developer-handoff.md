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
6. **Bidirectional coverage check (SKL-020) — run BOTH directions, not just REQ→ticket:**
   - Forward: every `REQ-` in scope maps to ≥1 `DEV-` ticket (the existing check).
   - **Reverse:** every ticket's real acceptance criteria/sub-tasks are checked against the actual
     REQ text — a ticket can *look* covered by a REQ number while doing something the REQ never
     described. Also flag any ticket implementing a function with **no REQ citation at all** —
     mint it as a DRAFT `REQ-` (reverse-engineered from the ticket, clearly labeled unconfirmed)
     rather than leaving it silently untraced.
   - Do this **at handoff time**, not only when an operator asks for an audit later. Caught live:
     a module handoff shipped with two real functions (one of them the module's most complex,
     critical-path capability) carrying zero requirement citation — found only when re-auditing
     weeks after the handoff was called done (RISK-026).
7. Surface at least one `REC-` (e.g. a slice that should be a spike first, or a risky dependency).
8. Write the handoff pack to `memory/clients/[client]/[project]/deliverables/documents/` and update
   `tasks.md`/`plan.md` with the `DEV-` IDs.

---

## Output format
```
DEVELOPER HANDOFF — [project] — [YYYY-MM-DD]
Stack: [target stack]   Source: [REQ set / design version]

COVERAGE CHECK
  Forward: [N] requirements → [N] tickets   (every REQ- maps to ≥1 DEV- · gaps: none / listed)
  Reverse: [N] tickets checked against real acceptance criteria (unbacked functions: none / listed
    — minted as DRAFT REQ- if found, per SKL-020)

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
- [ ] **Reverse-checked (SKL-020):** every ticket's real acceptance criteria matched against the
      REQ text it cites; any function with no REQ backing minted as a DRAFT `REQ-`, not left silent
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

---

## External-agent export (SKL-044, 2026-08-13)

When the operator hands work to a different coding agent (Codex, another Claude Code session
working directly in the app repo, etc.) that needs a self-contained doc bundle rather than a
ticket list — **generate that bundle from the canonical `memory/clients/[client]/[project]/`
files at export time**. Do not let the operator (or another session) hand-build a parallel
`docs/`+`sources/`+`memory/` tree that lives outside the standard lanes; it has no update path
back into `requirements.md`/`risks.md`/`decisions.md` and will silently drift from the moment it's
created.

**Caught live:** a separate session investigating `RevisionController.cs` directly in the app repo
produced a full `docs/`+`sources/`+`memory/` tree (ERDs, knowledge-base, test strategy, a
hand-maintained master-context doc, 3 investigation logs) parked in `reference/codex/` — 8 real
defects and 1 schema-authority conflict sat there undiscovered by `risks.md`/`decisions.md` for
the same day they were found, while `risks.md` was independently logging unrelated findings
(RISK-070–072) from the *same* day. Two authorities, no cross-reference, until a manual migration
pass (RISK-073–080, ADR-094) reconciled them.

**Export checklist, when producing a package for an external agent:**
1. Pull findings from `risks.md`/`decisions.md`/`requirements.md` — don't re-derive from scratch.
2. If the external session finds new defects, they come back as `RISK-`/`ADR-` entries in the
   same pass they're found, not accumulated in agent-local files for a later cleanup.
3. Evidence snapshots (schema dumps, SQL query output) go to
   `memory/clients/[client]/reference/`, matching the existing per-client reference convention —
   not a new top-level `sources/` tree.
4. Planning/spec docs go to `deliverables/documents/`; ERDs to `deliverables/diagrams/` — same
   target as every other deliverable this skill produces, so there is exactly one place to look.
5. A hand-maintained "master context" doc for the external agent is a smell: if it duplicates
   `database.md`/`decisions.md` in a different shape, it will drift the first time either side is
   updated alone. Prefer generating it from the canonical files (see `myps-db-asbuilt.md` /
   `scripts/generate-db-asbuilt.py` for the existing generated-not-hand-maintained pattern) over
   maintaining it by hand.

**Current MYPS authority:**
The MYPS Obsidian `Claude + Codex Real-Time Sync Protocol` and `Agent Tooling Mindmap` are the
shared startup authorities. Resolve the vault through `MYPS_VAULT_ROOT` or the documented
sibling-vault rule; do not depend on the retired machine-specific startup file.
