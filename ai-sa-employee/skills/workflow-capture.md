# Skill: workflow-capture  (command: `/capture-workflow`)

## Purpose
The mirror of `self-improvement`. Where that skill catches **what's broken**, this one catches
**what worked and should be replicated.** A senior who solves a problem cleanly the first time
and then loses the pattern is doomed to re-solve it. This skill locks in successful multi-step
workflows so they become reusable skills or skill-chains instead of one-off heroics.

> self-improvement = immune system (detect and fix problems).
> workflow-capture = muscle memory (keep what works).

Real example: schema design → interview → trace → review → drill was done by hand across
three sessions before anyone realized it was a *chain*. workflow-capture would have flagged it
after the **first clean run** — "this worked, it'll repeat, codify it" — instead of after the
third painful repetition.

## Trigger
- **Command:** "/capture-workflow", "capture this workflow", "that worked well, save the pattern",
  "should this be a skill", "i-save natin yung process".
- **Breadcrumb (passive):** when you finish a multi-step workflow that (a) had no guiding skill,
  (b) produced a clean result (operator confirmed / drill passed / no rework), and (c) will
  plausibly repeat — drop a one-line note in `memory/improvement-backlog.md` under *Workflow
  candidates*. No analysis at capture time.

## Minimum context required
- The sequence of steps actually taken (from the session, not idealized).
- Evidence it worked: operator approval, passing tests/drills, or zero rework.
- A judgment on generalizability — would this help a *different* project/client?

---

## Detection triggers (what earns a capture)

| Signal | Why it matters |
|---|---|
| **No skill guided it** | A repeatable workflow with no home is a gap waiting to cost time again |
| **Clean result** | Confirmed by the operator, a passing drill, or no rework — proof it's worth keeping |
| **Repetition likely** | The pattern will recur across modules, projects, or clients |
| **Independent re-derivation** | If subagents/sessions keep reinventing the same helper script or sequence, that's the strongest signal to bundle it |

The bar mirrors `self-improvement`: a single success isn't automatically a skill. Capture the
breadcrumb; let `/capture-workflow` or `weekly-review` decide if it clears the threshold.

---

## Steps — `/capture-workflow`
1. Read *Workflow candidates* in `memory/improvement-backlog.md` + anything from this session.
2. Reconstruct the **actual** step sequence — including the corrections that made it work, not
   the sanitized version. The corrections are often the valuable part.
3. Assess generalizability: project-specific / cross-project / universal. Project-specific
   patterns usually belong as a note in the client folder, not a global skill.
4. Choose the form (recommendation below) and, for a new skill or chain, draft the skeleton.
5. Present as a `WFC-` proposal. **STOP** — building it is a Tier 1 deliverable; hand off to
   `new-skill` on approval.
6. Move captured candidates to *Resolved* with the outcome.

---

## Capture output format
```
WFC-NNN — [workflow name]
─────────────────────────────────────────────────────────────────────────
Pattern:          [the step sequence actually taken]
Observed:         [N times, across which projects/sessions]
Success evidence: [drill pass / operator approval / no rework]
Generalizability: project-specific │ cross-project │ universal

Recommendation:
  A. New skill            — full skill file (skeleton below)
  B. Skill chain          — sequence of existing skills + the glue between them
  C. Standing instruction — lightweight rule in CLAUDE.md
  D. Log only             — not enough evidence yet; keep observing

Draft skeleton (if A or B):
  [Purpose / Trigger / Steps outline]

Dependencies: [existing skills it builds on]
```

---

## Integration
| Hooks into | How |
|---|---|
| `self-improvement` | The two cross-check: this flags successes self-improvement missed; self-improvement flags coverage gaps here. Both feed the same backlog file. |
| `weekly-review` | Reviews open `WFC-` candidates alongside `SKL-` proposals; promotes or retires. |
| `new-skill` | Receives an approved `WFC-` and turns the skeleton into a full skill. |
| `end-of-task` | Asks: did this task complete a clean, unguided, repeatable workflow? If so, one breadcrumb. |

## Quality checklist
- [ ] Reconstructed the real sequence incl. the corrections that made it work
- [ ] Generalizability judged honestly — project-specific stays in the client folder
- [ ] Success evidence is concrete (not "felt good")
- [ ] One-offs logged as candidates, not forced into skills
- [ ] Nothing built without a separate Tier 1 confirmation

## Failure exit
"No workflow candidates logged and nothing this session clears the bar (clean + repeatable +
unguided). I'll keep dropping candidates as good patterns emerge — run `/capture-workflow` later."
