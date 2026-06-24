# Skill: memory-hygiene  (command: `/check-memory`)

## Purpose
Keep the memory layer **lean and fast** so it never bloats context or crashes claude-mem.
The failure this prevents: entries accumulate forever, nothing is ever retired, and one day
session start injects hundreds of stale/duplicate entries — burning tokens and sometimes
taking the plugin down. The root cause isn't claude-mem; it's the absence of a *lifecycle*.
This skill is that lifecycle: things go in, and — when they're redundant, stale, or already
written to a lane file — they come back out.

We don't control the plugin's code, but we fully control **what goes in and what stays**.
That's enough.

## Trigger
- **Command:** "/check-memory", "check memory", "memory hygiene", "clean up memory",
  "memory is full", "claude-mem is slow", "linisin ang memory".
- **Auto:** runs as the **first step** of `weekly-review`; a quick dedup pass in `end-of-task`;
  and at session start *if* the active-entry count is over budget (warn, offer to run).

## Minimum context required
- claude-mem reachable (else operate on `memory/*.md` files only and say so).
- Read `memory/memory.md` and the relevant lane files to know what is already durably written.

---

## The memory budget

Three tiers, each with a different cost and lifecycle. The whole skill exists to keep entries
flowing **down** the tiers instead of piling up in the warm layer.

| Tier | Storage | Token cost | Lifecycle |
|---|---|---|---|
| **Hot** | `memory/memory.md` + lane files (`requirements.md`, `decisions.md`, …) | Read once per session (bounded) | Updated in place — never grows unbounded |
| **Warm** | claude-mem active entries — **soft cap ~50** | Injected selectively at session start | Compacted, promoted, or archived on each hygiene run |
| **Cold** | `memory/archive/claude-mem-archive.md` | **Zero** — read only on demand | Searchable history; never auto-injected |

The cap is the forcing function. When warm exceeds ~50 active entries, hygiene must bring it
back under by compacting, promoting, or archiving — in that order of preference.

---

## The three operations

### 1. COMPACT — merge related entries into one summary
Group entries that describe the same thing, replace them with a single dense entry that points
to the authoritative lane file.

```
BEFORE (5 entries, ~500 tokens):
  "renamed ProgramId to ProgramPK"
  "renamed ProgramUniqueId to ProgramId"
  "renamed ProjectId to ProjectPK"
  "renamed ProjectCode to ProjectId"
  "ADR-018 approved for column renames"
AFTER (1 entry, ~80 tokens):
  "ADR-018: column renames applied (ProgramPK/ProgramId/ProjectPK/ProjectId).
   Detail in decisions.md." tags: type:decision, project:myps
```

### 2. PROMOTE + PURGE — push the truth into a lane file, then drop the entry
claude-mem is episodic memory, not the system of record. If an entry duplicates what a lane
file already holds → verify the file has it → delete the entry. If the entry is important but
**not** yet in any file → write it to the correct lane file first → then delete the entry.
Memory must never be the *only* home for a decision.

### 3. ARCHIVE — cold-store the stale
Entries older than the retention window (default: not searched/touched in ~30 days or ~10
sessions) and not promoted → move to `memory/archive/claude-mem-archive.md`. Still findable by
reading the archive on demand; no longer injected into every session.

**Escalation:** if after all three the warm layer is *still* over budget, don't silently force
it — surface it in the digest and ask the operator to triage the borderline entries.

---

## Steps — `/check-memory`
1. Count active claude-mem entries; report against the ~50 budget (GREEN <40, AMBER 40–50, RED >50).
2. **Dedup against lane files** — for each entry, check whether `memory/memory.md` or a lane file
   already records it. If yes → verify → mark for PURGE.
3. **Cluster** the remainder by topic; mark clusters of 3+ for COMPACT.
4. **Age check** — mark entries past the retention window (and not promoted) for ARCHIVE.
5. Show the operator the plan (counts per operation) and **STOP** for confirmation — this mutates
   memory, so it is Tier 1.
6. On confirmation: execute PURGE (promoting first where needed) → COMPACT → ARCHIVE.
7. Report the before/after entry count and token estimate. Log a one-line summary to
   `memory/memory.md` working memory.

---

## Output format
```
MEMORY HYGIENE — [YYYY-MM-DD]
═══════════════════════════════════════
Warm layer: [N] active entries  →  budget ~50  →  🟢/🟡/🔴

Plan:
  Compact:  [N] entries → [M] summaries   (saves ~[X] tokens)
  Promote:  [N] entries → written to [lane files], then purged
  Purge:    [N] duplicates (already in lane files)
  Archive:  [N] stale entries → memory/archive/claude-mem-archive.md

After:  [N] active entries  (was [N])   ~[X] tokens lighter
Still over budget? [no / yes → borderline entries listed for your triage]
```

---

## Integration
| Hooks into | How |
|---|---|
| `weekly-review` | Runs as the first system-health step; result folds into the digest's "Memory tier" line. |
| `end-of-task` | Lightweight pass only: dedup what this task added, promote any decision to its lane file. No archiving. |
| session start | If count > budget, the environment check warns and offers `/check-memory` before work begins. |
| `self-improvement` | If claude-mem crashes or slows, that's a breadcrumb → may raise a `SKL-` to tune the budget/retention. |

## Quality checklist
- [ ] Nothing purged that wasn't first confirmed present in a lane file (promote-before-purge)
- [ ] Compacted summaries point to the authoritative source — no orphaned facts
- [ ] Archive is append-only; nothing destroyed, only moved to cold storage
- [ ] Operator confirmed the plan before any mutation
- [ ] Before/after counts reported honestly

## Failure exit
"claude-mem isn't reachable — can't run hygiene on the warm layer. Operating at file-memory
tier; I cleaned `memory/*.md` duplicates only. Re-run `/check-memory` when claude-mem is back."
