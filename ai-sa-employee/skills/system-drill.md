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

### Step 6 — Memory sync
**Verify:** claude-mem contains the drill entries (search `client:_drill`);
if claude-mem is unavailable, record the degraded tier as a finding — not a failure.

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

## Output format

```
SYSTEM DRILL — [YYYY-MM-DD]
═══════════════════════════════
1. Onboarding          PASS/FAIL — [detail if fail]
2. ID minting/Next-ID  PASS/FAIL
3. Mode write lanes    PASS/FAIL
4. Calibration         PASS/FAIL
5. Resume-client       PASS/FAIL
6. Memory sync         PASS/FAIL/DEGRADED
7. Cleanup             PASS/FAIL
═══════════════════════════════
Result: [N/7 PASS] — [system healthy / fix X before next client work]
```

If any step fails: identify the broken skill/file, propose the fix, and
log a `RISK-SYS` entry — a failing drill means real client work is at risk.

---

## Quality checklist
- [ ] All 7 steps executed (no early exit)
- [ ] Cleanup ran even if earlier steps failed
- [ ] All shell steps used repo-root absolute paths — no `cd` into `memory/clients/*`
- [ ] No drill `.md` data residue in memory/clients/ (`*.md` count = 0); Client Index row removed
- [ ] Any locked nested `.claude-mem` reported as residue-not-failure, with its exact path
- [ ] Failures traced to the specific skill/file responsible

## Failure exit
"Drill aborted at step [N] — cleanup completed. Broken: [component]. Fix before onboarding real clients."
