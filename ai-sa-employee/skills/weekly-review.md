# Skill: weekly-review

## Purpose
Proactive weekly sweep across ALL active clients and projects, plus a system
self-audit. The employee walks the floor instead of waiting to be asked:
aging risks, stale tasks, looming milestones, unanswered questions, and its
own gate compliance — all in one cross-client RAG digest.

## Trigger
Invoke when the operator says "weekly review", "portfolio check",
"sweep all projects", "lingguhang review", or "Monday review".
Also suggest it proactively if no weekly review has run in the last 7 days
(check claude-mem for the last `type:weekly-review` entry).

## Minimum context required
- At least one client in `memory/clients/`. If none: report system health only (Part B).

---

## Steps

### Part A — Portfolio sweep

For EVERY active project under `memory/clients/[client]/[project]/`:

1. **Aging risks** — read `risks.md`:
   - 🔴 RED risks open > 7 days with no movement → escalation candidate
   - 🟡 AMBER risks open > 14 days → review candidate
   - Risks with a trigger date inside the next 14 days
2. **Stale tasks** — read `tasks.md`:
   - In-progress tasks with no update > 7 days
   - Tasks past their due date
3. **Looming milestones** — read `plan.md`:
   - Milestones due within 14 days → status check
   - Milestones past target date not marked done → flag as slipped
4. **Unanswered questions** — read client record + `requirements.md`:
   - Open `[TBC]` items blocking work
   - Open client questions with no response logged
5. **Calibration check** — read `calibration.md`:
   - Completed work missing an actual → prompt to fill
   - Running ratio drifting beyond ±30% → flag estimation bias

### Part B — System self-audit (gate compliance)

1. `memory/memory.md` → Working Memory + Last Session updated within 7 days?
2. claude-mem reachable? Announce active memory tier if degraded.
3. Spot-check: do decisions/risks mentioned in recent claude-mem entries have
   matching IDs in the lane files? Flag any chat-only items.
4. Backup age: when was the last `employee-client-data_*.zip` created?
   (Check the backup folder; if > 7 days or never → recommend `scripts/backup.ps1`.)
5. **Proposal-decay check (SKL-052).** Re-read `memory/improvement-backlog.md`'s Proposals table.
   Any row still "Logged, not built" from more than one weekly-review cycle ago gets an explicit
   decision this pass — build it, decline it, or re-defer it with a fresh reason. A silent "still
   logged" is not a valid outcome; that's how SKL-047 sat unbuilt long enough to recur with a worse
   blast radius (a wrong answer, then a shipped code edit built on the same wrong premise).

### Part C — Digest

Output one cross-client digest (format below), store a summary in claude-mem
tagged `type:weekly-review`, and update Working Memory in `memory/memory.md`.

---

## Output format

```
WEEKLY REVIEW — [YYYY-MM-DD]
═══════════════════════════════════════

PORTFOLIO ([N] clients / [N] projects)

[Client] / [Project] — 🔴/🟡/🟢
  Risks:      [N] open — [aging items or "none aging"]
  Tasks:      [N] stale / [N] overdue
  Milestones: [next milestone + date — flag if <14d or slipped]
  Blocked on: [open TBCs / client questions — or "nothing"]
  Action:     [the ONE thing to do this week for this project]

SYSTEM HEALTH
  Working memory:  [fresh / stale Nd]
  Memory tier:     [Tier 2 / degraded → reason]
  Untracked items: [N chat-only decisions found — or "none"]
  Last backup:     [Nd ago / NEVER → run scripts/backup.ps1]
  Calibration:     [ratio status or "no data yet"]

TOP 3 THIS WEEK
  1. [highest-impact action across the portfolio]
  2. ...
  3. ...
```

---

## Quality checklist
- [ ] Every active project swept — none skipped
- [ ] Every flag has a concrete recommended action, not just a mention
- [ ] Digest stored in claude-mem (`type:weekly-review`)
- [ ] Working Memory updated with review date
- [ ] Backup age checked and reported

## Failure exit
"No clients found — ran system health only: [Part B results]"
