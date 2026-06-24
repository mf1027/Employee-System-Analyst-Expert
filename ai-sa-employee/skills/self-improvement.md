# Skill: self-improvement  (command: `/check-improvements`)

## Purpose
The agent's own continuous-improvement loop — **the system improving the system.**
Most improvement only happens when the operator notices something is off and asks.
That is pull-based and lossy: friction felt mid-task is forgotten by the time anyone
reflects on it. This skill makes improvement *cheap to capture* and *deliberate to act on*:

- A near-zero-cost **breadcrumb** records friction the moment it happens.
- A command-triggered **analysis** turns accumulated breadcrumbs into structured,
  decision-ready proposals — only when the operator asks, so it never burns tokens
  reflecting on itself in the background.

> Not to be confused with **B9 Continuous Improvement** in `skills.md` — that is the PM
> discipline (retrospectives, lessons learned) applied to *client projects*. This skill
> improves *the agent itself*: its skills, references, structure, and standing instructions.

## Trigger
- **Command (active analysis):** "/check-improvements", "check improvements",
  "what should we improve", "audit yourself", "any gaps in the system", "ano pwede pang i-improve".
- **Breadcrumb (passive capture):** no command. Whenever a detection pattern below fires
  during normal work, drop a one-line note in the backlog and move on. Do **not** stop to
  analyze — capture is cheap, analysis waits for the command.

## Minimum context required
- For the command: read `memory/improvement-backlog.md` (the breadcrumb log). If it's empty
  and nothing has surfaced this session, say so — don't invent gaps to look busy.
- For a breadcrumb: just the friction you observed. One line. No analysis.

---

## The two layers

| Layer | When it runs | Cost | What it does |
|---|---|---|---|
| **Breadcrumb** | Continuously, passively | ~zero (one line, no reasoning) | Logs friction to `memory/improvement-backlog.md` under *Breadcrumbs* |
| **`/check-improvements`** | Only when the operator asks | The thinking happens here | Reads breadcrumbs, clusters them, produces full `SKL-` proposals with pros/cons, effort/payoff, and a recommendation |

The split is the whole point: the expensive reasoning is opt-in. The passive layer cannot
navel-gaze because it does no reasoning — it just writes a timestamped line.

---

## Detection triggers (what earns a breadcrumb)

Drop a breadcrumb when you notice any of these. The bar is **a pattern, not a one-off** —
a single quirk isn't worth a skill. Note it; the threshold check happens at analysis time.

| Pattern | Smell | Example |
|---|---|---|
| **Repeated manual work** | Same multi-step task done by hand 3+ times | Migrating lookup tables one-by-one with no script |
| **Ad-hoc process** | A multi-step workflow with no skill guiding it | Building views/TVFs from a schema with no "design query objects" skill |
| **Skill fell short** | An existing skill didn't cover what was needed | `create-diagram` is Mermaid-only; needed a C4 model |
| **Recurring error** | The same class of mistake keeps happening | Column-mismatch bugs after a bulk rename — no "cascade rename impact" check |
| **Manual bridge** | Unstructured work between two skills | Schema design → developer handoff with no spec in between |
| **Post-mortem** | Something broke that a skill could have prevented | Seed generation failed on a circular dependency |

**Threshold + batching (the noise guard):** a breadcrumb is just a record. It only becomes a
proposal when (a) the operator runs `/check-improvements`, or (b) it recurs 3+ times, or
(c) `weekly-review` sweeps it up. Never interrupt active work to raise a proposal — that
is the failure mode this design exists to prevent.

---

## Steps — `/check-improvements`

1. Read `memory/improvement-backlog.md`. Note the `Next-ID` (SKL-NNN).
2. **Cluster** breadcrumbs by root cause — five "I did X by hand again" lines about the same
   gap are ONE proposal, not five. Pull in anything surfaced this session too.
3. Search claude-mem for related lessons (`mem search "[gap topic]"`) — a recurring root cause
   already noted as feedback strengthens the case.
4. For each cluster that clears the threshold, write a `SKL-` proposal in the format below.
   Be honest about effort and payoff — a proposal whose break-even is "never" should
   recommend **Do nothing**, not a new skill.
5. Apply the **triple lens** to each proposal: does the gap hurt SA work, PM work, or DBA work
   (or the system's own health)? State which.
6. Present proposals ranked by priority. Recommend the top action. **STOP** — building any
   skill from a proposal is a Tier 1 deliverable and needs its own confirmation.
7. Move acted-on or rejected breadcrumbs to the *Resolved* section with the outcome; increment
   `Next-ID` for every `SKL-` minted.

---

## Proposal output format

```
SKL-NNN — [short title]                                   Priority: 🔴/🟡/🟢
─────────────────────────────────────────────────────────────────────────
Problem:     [the friction, with a concrete example from the breadcrumbs]
Frequency:   [per-session / per-project / per-client — how often it bites]
Impact:      [what it costs if unfixed — time, rework, errors]
Lens:        [SA / PM / DBA / system-health — who this hurts]

Options:
  A. New skill            — build from scratch
  B. Enhance existing     — [which skill] + [what changes]
  C. Standing instruction — a rule in CLAUDE.md, no new file
  D. Do nothing           — accept the friction (sometimes correct)

Pros / Cons:
  A: + reusable, structured     │ - build + maintenance cost
  B: + fast, no new file        │ - risks overloading an existing skill
  C: + lightest                 │ - easy to ignore, no structure
  D: + zero cost                │ - friction persists

Effort vs payoff:
  Build cost:  [S/M/L]   Payoff per use: [S/M/L]   Break-even: ~[N] uses

Working analogy:
  "Right now you [current pain]. This would be like [familiar comparison] —
   instead of [manual thing] you'd [improved thing]."

Recommendation: [A/B/C/D] — [one line of reasoning]
Dependencies:   [other skills or restructuring needed first — or "none"]
```

---

## The breadcrumb log — `memory/improvement-backlog.md`

A passive line costs nothing and reads like:

```
- 2026-06-24 · repeated-manual-work · migrated 40 lookup tables by hand, no script · [myps]
```

Format: `- YYYY-MM-DD · <pattern> · <one-line observation> · [client or "system"]`.
No analysis, no IDs at capture time — IDs are minted only when a breadcrumb is promoted to a
`SKL-` proposal during `/check-improvements`.

---

## Integration

| Hooks into | How |
|---|---|
| `weekly-review` | Part B (system self-audit) runs `/check-improvements` over the backlog and folds the top `SKL-` into the digest. |
| `learn-from-feedback` | A correction the operator makes twice is itself a detection trigger → drop a breadcrumb. |
| `end-of-task` | Quick pass: did this task hit any detection pattern? If so, one breadcrumb before closing. |
| Quality Gate | Add the question: "Did anything this session earn a breadcrumb?" — keeps capture honest. |
| `new-skill` | When a proposal is approved as Option A, hand off to `new-skill` to build it. |

---

## Self-referential rule (this skill audits itself)

This skill is not exempt from its own radar. If `/check-improvements` is producing proposals
that never get acted on, if the format is too heavy to be useful, or if breadcrumbs aren't
being captured where they should be — **raise a `SKL-` against this skill.** The improvement
loop that can't improve itself is the first thing to fix.

Likewise, when `workflow-capture` exists, the two cross-check: this skill flags gaps in
workflow-capture's coverage, and workflow-capture flags successful patterns this skill missed.

---

## Quality checklist
- [ ] Every proposal traces to real breadcrumbs or in-session events — none invented
- [ ] Clusters merged by root cause (no duplicate proposals for one gap)
- [ ] Each proposal has honest effort/payoff and a clear recommendation (incl. "Do nothing")
- [ ] Threshold respected — one-offs stay as breadcrumbs, not proposals
- [ ] `Next-ID` incremented; resolved breadcrumbs moved out of the active list
- [ ] No skill built without a separate Tier 1 confirmation

## Failure exit
"Backlog is empty and nothing surfaced this session — no improvements to propose. I'll keep
dropping breadcrumbs as friction comes up; run `/check-improvements` again after more work."
