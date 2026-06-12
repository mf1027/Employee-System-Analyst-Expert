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
5. **Pattern surfacing:** search claude-mem `mem search "lesson [root cause keyword]"`.
   If 3 or more similar root causes exist, flag: "I've seen this 3+ times — should
   I update the relevant skill to handle this pattern?"
6. **Memory.md cap check:** if `memory/memory.md` is approaching 150 lines, warn
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
[Pattern surfaced: "..." — if applicable]
[Memory.md cap warning: at [N] lines — if applicable]
```

## Failure exit
"No task referenced. Tell me which task to close and I'll write the lesson."
