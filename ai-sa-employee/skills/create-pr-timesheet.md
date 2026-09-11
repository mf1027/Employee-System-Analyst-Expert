# Skill: create-pr-timesheet

> **Wired 2026-09-11.** Registered in the root `CLAUDE.md` trigger table, indexed in
> `ai-sa-employee/skills/skills.md` §6, and has a `.claude/commands/create-pr-timesheet.md`
> wrapper — the standard three-piece registration every other employee skill gets. Originally
> drafted directly inside `project_myps/.claude/skills/create-pr-timesheet/`, then moved here at
> the operator's request ("I want the skill to be in the employee agent not in the repo for now
> since it still needs enhancement"); it stayed here rather than being vendored back into a client
> repo (the way `plan-analysis` was, per ADR-136) since it's still a single-repo (MYPS) tool with
> the "Known gaps" below unresolved. Promote it to a vendored client-repo copy only once those gaps
> close and it's proven across a second repo.

## Purpose
Produce a manual-PR title and a single copy-ready PR body — with a one-line timesheet entry embedded
inside that same body, hidden via an HTML comment — from a git branch's actual history. Built after
repeatedly hand-producing this exact 3-part deliverable (title, body, timesheet) during a MYPS session;
packaging it removes the need to redo that synthesis by hand every time.

## Trigger
"PR title and body", "create a manual PR", "give me the PR body", "timesheet entry", "PR + timesheet" —
even if the operator doesn't say "skill". Do not wait for a manual "use the skill" instruction.

## Minimum context required
- A git repo with a current branch and a base branch to diff against (defaults to the repo's own main
  integration branch — e.g. `dev-trunk` for MYPS — unless the operator names a different one).
- Read-only git access: `log`, `diff`, `branch`, `status`. Never `add`/`commit`/`push`, never
  `gh pr create` — this skill only prints text for the operator to paste manually themselves.

---

## Non-negotiable output rules

- **Never include a "🤖 Generated with Claude Code" footer anywhere in the PR body.** Explicit,
  standing operator correction (MYPS session, 2026-09-11) — do not reintroduce it.
- **The timesheet is not optional.** Every PR title/body produced by this skill includes the embedded
  timesheet automatically, without a separate request — corrected live after once giving a PR body
  without it and the operator immediately flagging the omission.
- **Read-only.** No git mutation, no PR creation, no application-code or config changes.

## Steps

### 1. Determine the diff range
- Current branch via `git branch --show-current` (or the operator-named branch if they're asking about
  one that isn't checked out — use `origin/<branch>` refs after an explicit `git fetch`, as done live
  for `feature/dashboard-map-region-labels` in the MYPS session this was drafted in).
- Base branch: ask or infer from the repo's own merge-commit history (look for the branch everything
  else merges into) if not obviously named in the request.
- Gather, all read-only: `git log <base>..<branch> --oneline`, `git diff <base>...<branch> --stat`, and
  each commit's FULL message via `git log <base>..<branch> --format="%H%n%B%n---COMMIT-END---"`.

### 2. Decide source depth per commit
If commit messages are already detailed (root cause, fix, verification — this repo's own established
convention when commits are written well), synthesize the PR body FROM those messages rather than
re-deriving causes from a full diff re-read.

**If commit messages are thin (one-liner subjects, no body)** — confirmed necessary live: MYPS's
`feature/dashboard-map-region-labels` branch had exactly this shape — fall back to reading the actual
diff (`git diff <base>...<branch>` per file, or via a research subagent if the diff is large) before
writing anything. Do not guess what a change does from its filename or commit subject alone; a thin
commit message is not evidence of what the diff actually contains — confirmed live twice: the diff
turned out to bundle a second, entirely unrelated feature (a Revision Queue KPI) that the branch name
and commit subjects gave zero indication of, and a third, accidental-looking dev-config change
(`appsettings.Development.json`'s connection string pointed at a different local DB) that would have
gone unflagged without actually reading the diff.

### 3. Sweep for bundled-but-unrelated changes before writing the body
Do not assume a branch's diff matches its name/commit subjects. If the diff touches files or logic that
don't obviously relate to what the branch name or commits describe, say so explicitly in the PR body as
its own subsection — do not fold an unrelated change into the main narrative as if it were part of the
feature, and do not silently omit it either. If a change looks like it might be accidental (e.g. a
local-environment config value committed by mistake), flag it plainly as a caution for the reviewer,
with a recommendation (e.g. "recommend reverting before merge"), rather than passing it through neutrally.

### 4. Synthesize the title
Concise, under 70 characters, representative of everything on the branch — not just the latest commit
or the branch's own name. If the branch bundles 2+ unrelated changes (per step 3), the title should
make that legible rather than picking one and hiding the other.

### 5. Synthesize the body
One `###`-headed subsection per logical/independent change (root cause or purpose, what changed, what
was verified, what's explicitly out of scope), plus a `## Test plan` checklist — checked items for what
was actually verified, unchecked items for manual smoke tests still needed. A flagged/suspicious bundled
change (step 3) gets its own clearly-marked subsection, e.g. "⚠️ Flag: ...".

### 6. Append the embedded, hidden timesheet
Last thing **inside** the same body block, after the Test plan — not a separate block after the fence
closes:
```
<!-- [TIMESHEET_START]
...one dense sentence: what was fixed/reviewed, concrete evidence or impact, not a restatement of the whole body...
[TIMESHEET_END] -->
```
**Caught live, 2026-09-11:** delivered a PR body with the timesheet as its own separate block sitting
*after* the closing code fence instead of inside it — despite this exact rule already being written down
here. The operator had to say "can you just include the timesheet start in the pr body that is ready to
copy" before it was corrected. The failure mode isn't forgetting the timesheet (Step "Non-negotiable
output rules" already covers that) — it's placing it outside the copy-paste boundary so the operator has
to copy two separate things instead of one. Before finalizing any PR body output, check literally: is the
`<!-- [TIMESHEET_START] ... -->` comment the last line *inside* the fenced block, with nothing after the
closing triple-backtick except (optionally) the title line above it? If it's sitting below the fence,
that's the bug this note exists to catch.

### 7. Output shape
1. PR Title on its own line, plain text (not fenced — GitHub's title field is separate from the body).
2. Exactly ONE fenced markdown block containing the full body — every subsection, the Test plan, and
   the trailing HTML-comment timesheet, all inside that single block, so one copy is everything needed.
   Nothing — not even the timesheet — follows the closing fence.

## Known gaps (carry forward — not blockers to using the skill, but don't claim they're solved)

- No bundled script — everything above is prose instruction, re-derived by hand each invocation rather
  than automated (e.g. no script to pull `git log`/`diff` and pre-format it).
- Base-branch inference (step 1) has only been exercised against MYPS's `dev-trunk` convention; untested
  against a repo with a differently-named or less obvious integration branch.
- No handling yet for a branch with zero commits ahead of base, or one that's already fully merged.
- Registered via the standard `.claude/commands/` wrapper this session, but not yet exercised end-to-end
  through the `Skill` tool in a live invocation (wrappers only become live-discoverable in a fresh
  session, not the one that created them) — confirm on first real use that the trigger fires and the
  wrapper's `$ARGUMENTS` hand-off reads correctly, and update this note once it has.
