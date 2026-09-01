# DBA Skill Chain — Drill Findings & Improvement Plan

**Date:** 2026-06-18
**Author:** System Analyst (self-audit, CHALLENGE + PLAN mode)
**Subject:** The 5-skill DBA chain created 2026-06-18
(`dba-process-interview` → `dba-schema-ingest` → `dba-data-flow-trace` → `dba-schema-review` → `dba-schema-drill`)
**Method:** Ran `dba-schema-drill` methodology against the chain itself, using the imminent
"Design Project Components schema" task as the test scenario.

> **Meta-point:** these skills were written by the same reasoning that produced the 3-revision
> Programs failure. They are untested hypotheses, not proven fixes. This document tests them
> before they are trusted.

---

## Drill result: FAIL

| Step | Verdict | Break |
|---|---|---|
| 0. Invoke the chain | 🔴 FAIL | No mechanism forces invocation — self-enforcement only |
| 1. process-interview | 🔴 FAIL | Runs before ingest → can't ask sharp questions blind; no fallback when operator doesn't know |
| 2. schema-ingest | 🟢 PASS | Parser exists and works |
| 3. data-flow-trace | 🟠 PARTIAL | Critical questions depend on step 1, which couldn't ask them (circular) |
| 4. schema-review | 🟠 PARTIAL | "Flag everything as options" → interrogation, violates CLAUDE.md no-interrogation rule |
| 5. schema-drill | 🟠 PARTIAL | Produces SQL that is never executed → false confidence |

---

## Findings (flag, don't fix — operator decides)

### F-001 · Critical · No enforcement mechanism
**Issue:** The chain is a set of `.md` files invoked only if I remember to. The original failure
WAS forgetting the process. A skill that requires the discipline it's meant to supply is circular.
**Evidence:** Files live in `ai-sa-employee/skills/` but are not in the Skill tool, not indexed in
`skills.md`, not in the CLAUDE.md trigger table. Nothing gates them.
**Impact:** Next session reproduces this session's failure — the skills sit unused.
**Options:**
  - A. Tie the chain to the **existing** CLAUDE.md Understanding-Check hard gate (which IS enforced):
    add "schema work → DBA chain" to the trigger table + Standing Instructions, so the gate that
    already stops me before deliverables also routes schema work through the chain.
  - B. Add a one-line pre-flight checklist to `database-admin.md` that must be answered ("interview done? ingest done?") before any schema output.
  - C. Both (recommended).

### F-002 · Critical · Not registered / not discoverable
**Issue:** 5 new skills + 1 edit, but `skills.md` index and the CLAUDE.md Skills Library section
were never updated. Orphaned skills are invisible skills.
**Evidence:** `ai-sa-employee/skills/skills.md` and root CLAUDE.md "Skills Library" / trigger table
have no reference to the `dba-*` skills.
**Impact:** Even a disciplined future-me won't find them.
**Options:** A. Register all 5 in `skills.md` + CLAUDE.md trigger table + Skills Library list.

### F-003 · High · Interview-before-ingest is the wrong order
**Issue:** The chain is linear: interview → ingest. But you cannot ask sharp process questions
about a schema you haven't seen. This session, *ingest generated the questions* (RevisionNumber,
per-stage GUID, tUsersv2). Strict interview-first is backwards.
**Impact:** Step 1 produces generic questions; the schema-specific ones surface too late (step 3),
causing the rework the chain was meant to prevent.
**Options:**
  - A. Reorder to **quick-ingest → interview (informed) → deep-trace**, with an explicit loop:
    ingest gives the structure, the interview is then schema-aware, and new facts loop back.
  - B. Keep order but allow a "structural pre-read" inside the interview step.

### F-004 · High · The drill is never executed → false confidence
**Issue:** `dba-schema-drill` produces "runnable SQL" but it is run nowhere (no live DB in this
environment). This session shipped 3 bugs that only appeared on execution (UTF-16 decode, `%%` in
mermaid erDiagram, Python operator precedence). Paper drills miss exactly those.
**Impact:** "Drill passed" can mean "the SQL looks right," not "the SQL works."
**Options:**
  - A. Rename the pass criterion to **"syntax-reviewed, UNVALIDATED until executed on a real DB"**
    and require the operator (or a CI step) to run it before "locked."
  - B. Add a lightweight validator path (e.g., parse the SQL, or run against a local SQL Server /
    sqlcmd / a container) where available.
  - C. Both — honest labeling now, real execution when a DB is available.

### F-005 · High · "Flag, don't fix" becomes interrogation
**Issue:** `dba-schema-review` says present every finding as options for the operator. On a 15-table
schema that's 40+ decisions — which violates the CLAUDE.md "no interrogation, tap-friendly choices"
standing rule.
**Impact:** Either the operator is overwhelmed, or I batch-decide silently (the original sin).
**Options:**
  - A. Add a **severity threshold**: auto-apply/recommend Low-severity with a default + batch them
    in one summary; only BLOCK and ask on High/Critical findings (max ~4 at a time per the
    AskUserQuestion limit).
  - B. Keep flag-all but group findings so the operator approves in batches.

### F-006 · Medium · No protocol when the operator doesn't know
**Issue:** `dba-process-interview` Q4 ("by design or by bug?") assumes someone can answer. The
operator is a newbie; the original dev may be unavailable.
**Impact:** Interview stalls, or falls back to guessing — the failure it was meant to prevent.
**Options:** A. Add an "unknown answer" rule: if a CRITICAL answer is unknown, mark the design
PROVISIONAL + log ASS-NNN + flag the specific risk; if a non-critical answer is unknown, proceed
with a stated default. Never silently guess a critical one.

### F-007 · Medium · Too heavyweight for small changes
**Issue:** Running all 5 steps for "add one nullable column" is disproportionate. Heavy process
gets skipped or ritualized — both reproduce the failure.
**Impact:** Either the chain is abandoned for "small" work (which is how big problems start), or
it's box-ticked without rigor.
**Options:** A. Define a **Lite path** (column add/rename/type change on an existing, already-ingested
table → review + mini-drill only) vs **Full path** (new table / restructure / merge → all 5 steps).

### F-008 · Medium · No re-entry loop when facts arrive mid-design
**Issue:** The chain is linear; this session, new facts ("Name changes per stage," "tUsersv2 dead,"
"ProgramUniqueId per stage") arrived DURING design and forced rework. The chain doesn't model the loop.
**Impact:** Mid-stream discoveries aren't systematically fed back; they get patched ad hoc.
**Options:** A. Add an explicit **loop-back rule**: any new behavioral fact → return to interview
(amend), re-trace the affected steps, re-review. Make the loop a named part of the chain, not an exception.

### F-009 · Medium · Overlap with existing skills
**Issue:** `dba-schema-ingest` overlaps `ingest-reference`; `dba-schema-drill` overlaps `system-drill`;
`dba-process-interview` overlaps `gather-requirements` and the existing Understanding Check.
**Impact:** Ambiguity about which to use; maintenance drift between near-duplicate skills.
**Options:** A. Cross-reference instead of duplicating — each `dba-*` skill states how it specializes
its general cousin (e.g., "this is `ingest-reference` for DDL specifically").

### F-010 · Medium · Overfitting to MYPS
**Issue:** The chain bakes MYPS-specific lessons ("always ask about per-stage history") into general
DBA guidance. Stage-based versioning is a MYPS trait, not a universal one.
**Impact:** On a simple CRUD app, the chain asks irrelevant questions → noise, lost credibility.
**Options:** A. Frame the lessons as **conditional prompts** ("IF the entity has states/stages, ask
about per-stage history") rather than unconditional rules.

### F-011 · Low · No measurement / calibration
**Issue:** No way to know if the chain reduced rework. `calibration.md` exists in the project scaffold
but the chain doesn't feed it.
**Impact:** Can't tell if this helped or just added ceremony; can't improve it with evidence.
**Options:** A. After each schema task, log to `calibration.md`: revisions-before-lock, rework cause,
which step (if any) caught it. Review periodically.

---

## Remediation Plan

Prioritized. P1 = fixes the FAIL conditions (do first), P2 = high-value correctness, P3 = polish.

| Task | Fixes | Effort | Change |
|---|---|---|---|
| **T1 — Register the chain** | F-001, F-002 | S | Add 5 skills to `skills.md` index + CLAUDE.md "Skills Library" + add a trigger-table row: "schema design/restructure → DBA chain". Tie invocation to the existing Understanding-Check hard gate (the one mechanism that IS enforced). |
| **T2 — Reorder to iterative** | F-003, F-008 | S | Rewrite the chain order to **quick-ingest → informed-interview → trace → review → drill**, with a named **loop-back** step: any new behavioral fact returns to interview. Update `database-admin.md` chain diagram + each skill's prerequisites. |
| **T3 — Honest drill labeling** | F-004 | S | In `dba-schema-drill`: change pass criteria to "syntax-reviewed; status = UNVALIDATED until executed on a real DB." Add an execution/validation section (sqlcmd / container / CI). Never report "passed" for an unrun script. |
| **T4 — Severity threshold in review** | F-005 | S | In `dba-schema-review`: Low → recommend a default + batch in one summary; Medium → batch; High/Critical → block and ask (≤4 per round). Aligns with CLAUDE.md no-interrogation rule. |
| **T5 — Unknown-answer protocol** | F-006 | S | In `dba-process-interview`: if a CRITICAL answer is unknown → design is PROVISIONAL + ASS-NNN + named risk; non-critical unknown → proceed with stated default. Never guess a critical answer silently. |
| **T6 — Lite vs Full path** | F-007 | S | In `database-admin.md`: define Lite (small change on ingested table → review + mini-drill) vs Full (new/restructured table → all steps). |
| **T7 — De-dup via cross-reference** | F-009 | S | Add a "Relationship to general skills" note in each `dba-*` skill pointing to its general cousin; remove duplicated instructions. |
| **T8 — Conditional prompts** | F-010 | S | Reframe MYPS-specific lessons as IF/THEN prompts (e.g., per-stage history question only fires for staged/versioned entities). |
| **T9 — Calibration hook** | F-011 | S | Add a closing step to `dba-schema-drill`: log revisions-before-lock + rework cause to `calibration.md`. |

### Recommended sequence

```
Phase 1 (unblock — makes the chain real):     T1, T2, T3
Phase 2 (correctness — makes it safe to use): T4, T5, T6
Phase 3 (polish — makes it durable):          T7, T8, T9
```

Phase 1 alone converts the drill result from FAIL to PASS-with-caveats; the chain becomes
discoverable, correctly ordered, and honest about the drill's limits. Phases 2–3 refine.

---

## The deeper lesson

The chain failed its own drill for the same root reason the Programs schema failed: **I built the
artifact before testing how it behaves in use.** Writing five well-structured skill files *felt*
like fixing the problem — but a process that depends on my discipline to invoke it cannot fix a
discipline gap. The only durable fix (T1) is to attach the chain to a gate that is *already
enforced* (the Understanding Check), not to add a sixth thing I must remember.

*No skills modified yet — this plan is for approval first.*
