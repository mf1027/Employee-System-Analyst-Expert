# Skill: system-drill

## Purpose
End-to-end smoke test of the employee system using a synthetic client.
Run after any change to skills, CLAUDE.md, or scripts — validates that the
whole pipeline (onboard → project scaffold → IDs → resume → cleanup) still
works before a real client depends on it.

## Trigger
Invoke when the operator says "run a drill", "test the system",
"system check", "smoke test the employee", or after the operator confirms
a batch of system changes.

## Minimum context required
None. The drill is fully self-contained and uses canned answers.

---

## Drill sequence

Use client name `_drill` (leading underscore = synthetic, never a real client).
Run every step; record PASS/FAIL per step; do not stop on first failure.

> **Shell-path guardrail (Windows-critical).** Run every shell command with **absolute paths
> from the repo root**. **Never `cd` into `memory/clients/*`** (or any subfolder of it). Because
> `CLAUDE_MEM_DATA_DIR=./.claude-mem` is CWD-relative, a shell whose working directory sits inside
> a client folder makes claude-mem spawn a **project-local `.claude-mem` store there** — which the
> live claude-mem process then holds open, so it cannot be deleted mid-session on Windows (leaves
> un-cleanable residue at Step 7). Use file tools (Read/Write/Edit) for the scaffold, and keep any
> shell command rooted at the repo, e.g. `Remove-Item "<repo>\memory\clients\_drill" -Recurse -Force`.

### Step 1 — Onboarding (new-client-setup)
Run the wizard with canned answers:
- Client: `_drill` | Project: `smoke-test`
- Problem: "Manual inventory counting takes 2 days monthly"
- Type: A (new build) | Go-live: +90 days (absolute date) | Dev team: Yes
- Stack: React / Node.js / PostgreSQL / AWS / none

**Verify:** `memory/clients/_drill/_drill.md` exists with the tech stack;
`memory/clients/_drill/smoke-test/` has all 10 files + deliverables/ subfolders;
Client Index in `memory/memory.md` has a `_drill` row.

### Step 2 — ID minting + Next-ID
Add one entry of each type to the project files:
REQ-F01, RISK-001, ADR-001, TASK-001, ASS-001.

**Verify:** each lane file's `Next-ID` header was incremented after the write
(e.g. requirements.md now says `Next-ID: REQ-F02`).

### Step 3 — Mode write lanes
Write one line to each lane as its mode would:
DISCOVER→requirements.md, ANALYZE→risks.md, DESIGN→decisions.md, PLAN→plan.md.

**Verify:** all four files contain the drill entries; no file was written
to the wrong lane.

### Step 4 — Calibration
Log a fake estimate (PERT 3d) in `calibration.md`, then a fake actual (4d).

**Verify:** ratio computed (1.33) and present in the running accuracy section.

### Step 5 — Resume (resume-client)
Run the resume-client flow against `_drill` as if freshly copied.

**Verify:** status card shows the project, the open RISK-001, TASK-001,
and the next milestone; no crash on the synthetic data.

### Step 6 — Memory sync (Tier 0, corrected 2026-08-24 — see Gap Analysis below)
This system runs at **Tier 0 — file memory only** (`CLAUDE.md` Memory Tiers, ADR-111,
2026-08-23). claude-mem is confirmed dead — its store has not been written since 2026-07-02, and
its MCP tools do not connect. This is a **structural fact**, not a per-run degradation, so it is no
longer something this step "checks for" each time.

**Verify instead:** the drill's entries actually landed in file memory — `memory/memory.md`'s
Client Index has the `_drill` row (already checked in Step 1) and the lane files written in Step 3
are the durable record. If context-mode (`ctx_search`) is available, optionally confirm it indexed
this session's `_drill` activity — but its absence is not a drill failure either; it is not the
system of record.

### Step 7 — Cleanup (always runs, even after failures)
1. Delete `memory/clients/_drill/` entirely — use an **absolute path from the repo root**
   (e.g. `Remove-Item "<repo>\memory\clients\_drill" -Recurse -Force`), never a `cd`-relative one.
2. Remove the `_drill` row from the Client Index in `memory/memory.md`.
3. Note: claude-mem `_drill` entries stay (harmless, tagged synthetic).

**Verify:** no `_drill` traces left in `memory/clients/` or the Client Index.

> **Windows lock edge case.** If a nested `.claude-mem` folder appears under the project and the
> delete fails with "in use", a claude-mem process is holding its log open. This is **residue, not
> drill data** — confirm the drill `.md` files are gone (`*.md` residue count = 0), report cleanup
> as PARTIAL with the exact leftover path, and note it clears when the session ends. Do not treat a
> locked `.claude-mem` as a drill failure. (Avoid it entirely via the Shell-path guardrail above.)

---

## Root Cause Analysis (added 2026-08-24) — required whenever any step is FAIL

A one-line "identify the broken skill/file, propose the fix" was the entire failure-handling
instruction before this pass — that asks for thought but doesn't structure it, and doesn't
distinguish a genuine new defect from a drill that's stale on its own assumptions. **Both classes
have already happened in this engagement**: `tools/verify-function-sql-mindmap.ps1` went 47/52 for
a week because 5 of its checks required files that had been deliberately deleted (ADR-107/108) —
the drill was wrong, not the thing it tested (fixed 2026-08-23, ADR-111). Don't repeat that here
silently; the Gap Analysis below exists specifically to catch that class before it hides for a week.

For **every** FAIL, report all three fields — do not skip any, even if the answer is "unknown":

1. **Mechanism** — the specific skill/file/config responsible, not just "step N failed." Point at
   the exact line or setting, the way this drill's own Step 6 fix (above) names `CLAUDE.md`'s
   Memory Tiers section rather than saying "memory is broken."
2. **Since when** — `git log -1 --format=%cd -- <file>` (or the file's mtime if untracked) on the
   responsible file. Dates the regression instead of just asserting it exists.
3. **New or recurring** — search `memory/improvement-backlog.md` for the same failure pattern
   (breadcrumbs are timestamped one-liners, cheap to scan). If this is the **3rd+** occurrence of
   the same root cause, that already crosses `self-improvement.md`'s own threshold for a `SKL-`
   proposal — log it as one, don't just re-add another one-off `RISK-SYS` entry for a pattern
   that's already recurring.

## Gap Analysis (added 2026-08-24) — required every run, PASS or FAIL

**A green drill on a stale assumption is worse than a red one** — nothing else prompts a second
look. Run this checklist every time, independent of the PASS/FAIL result above:

- [ ] Does each of the 7 steps still test what it claims to, against `CLAUDE.md`'s **current**
      content — not what was true when `system-drill.md` was last edited? (Re-read the relevant
      `CLAUDE.md` section for any step whose claim depends on system state, e.g. Step 6's memory
      tier.)
- [ ] Has anything been added to the system since `system-drill.md`'s own last-modified date
      (`git log -1 -- ai-sa-employee/skills/system-drill.md`) that isn't exercised by any step — a
      new lane-file type, a new memory tier or mechanism, a new hook, a new ID prefix?
- [ ] Report drift as a finding even when all 7 steps PASS. "Gap Analysis: clean, no drift found"
      is itself the expected, positive result of running this checklist — silence is not the same
      as having checked.

---

## Output format

```
SYSTEM DRILL — [YYYY-MM-DD]
═══════════════════════════════
1. Onboarding          PASS/FAIL — [detail if fail]
2. ID minting/Next-ID  PASS/FAIL
3. Mode write lanes    PASS/FAIL
4. Calibration         PASS/FAIL
5. Resume-client       PASS/FAIL
6. Memory sync (Tier 0) PASS/FAIL
7. Cleanup             PASS/FAIL
═══════════════════════════════
Result: [N/7 PASS] — [system healthy / fix X before next client work]

ROOT CAUSE ANALYSIS — [present only if any step FAILed; omit this block entirely on a clean pass]
  Step [N] — Mechanism: [exact file/skill/setting]
             Since when: [date, from git log/mtime]
             New or recurring: [new | recurring, Nth time — see improvement-backlog.md]

GAP ANALYSIS — [always present, every run]
  [ ] All 7 steps still match current CLAUDE.md content
  [ ] No system additions since system-drill.md's last edit are unexercised
  Result: [clean, no drift found | drift found: <what, and where logged>]
```

If any step fails: identify the broken skill/file, propose the fix, log a
`RISK-SYS` entry (or a `SKL-` proposal if Root Cause Analysis found this is
the 3rd+ occurrence of the same pattern) — a failing drill means real client
work is at risk.

---

## Quality checklist
- [ ] All 7 steps executed (no early exit)
- [ ] Cleanup ran even if earlier steps failed
- [ ] All shell steps used repo-root absolute paths — no `cd` into `memory/clients/*`
- [ ] No drill `.md` data residue in memory/clients/ (`*.md` count = 0); Client Index row removed
- [ ] Any locked nested `.claude-mem` reported as residue-not-failure, with its exact path
- [ ] Failures traced to the specific skill/file responsible
- [ ] Root Cause Analysis present and structured (mechanism / since-when / new-or-recurring) for
      every FAIL — not just named in prose
- [ ] Gap Analysis run and its result stated even on a fully clean pass — "clean, no drift found"
      is a required line, not an implied default

## Failure exit
"Drill aborted at step [N] — cleanup completed. Broken: [component]. Fix before onboarding real clients."
