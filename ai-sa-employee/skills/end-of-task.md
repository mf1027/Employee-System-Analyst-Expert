# Skill: end-of-task

## Purpose
Close out a completed task: write a depth-checked lesson to **claude-mem**,
update the working memory section in `memory/memory.md`, and surface patterns
if the same kind of problem keeps recurring.

## Trigger
Invoke when the operator says "done", "task complete", "wrap this up",
or when a task has been confirmed as finished.

## Minimum context required
- A reference to the task that was completed.

## Steps
1. Read `memory/memory.md` (Working Memory section — current tasks).
2. Compose a lesson entry. **Depth check:** the entry MUST include a specific root
   cause AND a lesson-learned, not just a description of what was done.
   If the draft is shallow (e.g. "completed the requirements"), rewrite before saving.
3. Store the lesson in claude-mem via `memory_add`:
   - **Title:** `Lesson — [task name] — [YYYY-MM-DD]`
   - **Content:** root cause + resolution + lesson (what to do differently next time)
   - **Tags:** `type:lesson`, `client:[name]` (if applicable), `project:[name]` (if applicable)
4. Update Working Memory in `memory/memory.md` — mark the task complete.
5. **Calibration entry:** if the task had an estimate (check the project's
   `calibration.md` and `plan.md`), log the actual time/effort against it and
   recompute the running ratio. If no estimate existed, note that — unestimated
   work is itself a finding.
6. **Pattern surfacing:** search claude-mem `mem search "lesson [root cause keyword]"`.
   If 3 or more similar root causes exist, flag: "I've seen this 3+ times — should
   I update the relevant skill to handle this pattern?"
7. **Session-close audit — gate compliance check.** Before closing, verify and
   report honestly:
   - [ ] Every decision/risk/requirement mentioned this session has an ID in the
         correct lane file — nothing left in chat only
   - [ ] `Next-ID` headers incremented in every file that received new IDs
   - [ ] Working Memory + Last Session in `memory/memory.md` updated with today's date
   - [ ] Any superseded entries marked, not duplicated
   If any item fails: fix it NOW, before reporting the task closed. A task is not
   closed until the audit passes.
8. **Memory.md cap check:** if `memory/memory.md` is approaching 150 lines, warn
   and offer to archive oldest entries to `memory/archive.md`.

## Output format
```
TASK CLOSED: [task name]
Lesson stored in claude-mem:
  Title: Lesson — [task name] — [YYYY-MM-DD]
  Root cause: [specific cause — not just "the thing was wrong"]
  Resolution: [what was done]
  Lesson: [what to do differently or watch for next time]
  Tags: type:lesson, [client/project tags]

Working memory updated: [what changed]
Calibration: [estimate Xd vs actual Yd, ratio Z — or "no estimate existed"]
Session-close audit: [PASS / fixed N items before close]
[Pattern surfaced: "..." — if applicable]
[Memory.md cap warning: at [N] lines — if applicable]
```

## Failure exit
"No task referenced. Tell me which task to close and I'll write the lesson."
