# Skill: self-improvement  (command: `/check-improvements`; alias: `/capture-workflow`)

## Purpose
The agent's own continuous-improvement loop — **the system improving the system.** One
self-audit, **two lenses**:

- **Lane A — Friction (immune system):** catches what's *broken* → `SKL-` proposals.
- **Lane B — Success (muscle memory):** catches what *worked and should be replicated* →
  `WFC-` proposals. A senior who solves something cleanly once and then loses the pattern is
  doomed to re-solve it; this lane locks the pattern in as a reusable skill or chain.

Improvement is otherwise pull-based and lossy — friction *and* good patterns felt mid-task are
forgotten by the time anyone reflects. This skill makes both **cheap to capture** (one-line
notes, no reasoning) and **deliberate to act on** (the command does the thinking, only when asked).

> Not to be confused with **B9 Continuous Improvement** in `skills.md` — that is the PM
> discipline (retrospectives, lessons learned) applied to *client projects*. This skill
> improves *the agent itself*: its skills, references, structure, and standing instructions.

## Trigger
- **Command (active analysis):** "/check-improvements", "check improvements", "what should we
  improve", "audit yourself", "any gaps in the system", "ano pwede pang i-improve".
  Alias **"/capture-workflow"** / "capture this workflow" / "that worked, save the pattern" /
  "should this be a skill" — enters the same skill, emphasis on Lane B.
- **Passive capture (no command):** when a detection pattern below fires during normal work,
  drop a one-line note in the backlog and move on. Friction → *Breadcrumbs*; a clean repeatable
  workflow → *Workflow candidates*. Do **not** stop to analyze — capture is cheap, analysis
  waits for the command.

## Minimum context required
- For the command: read `memory/improvement-backlog.md` (both *Breadcrumbs* and *Workflow
  candidates*). If empty and nothing surfaced this session, say so — don't invent items to look busy.
- For a passive note: just the friction or the workflow you observed. One line. No analysis.

---

## The two layers × two lanes

| Layer | Lane A (friction) | Lane B (success) | Cost |
|---|---|---|---|
| **Passive** | one-line *Breadcrumb* | one-line *Workflow candidate* | ~zero (no reasoning) |
| **Active** (`/check-improvements`) | cluster → `SKL-` proposals | review → `WFC-` proposals | the thinking happens here |

The split is the whole point: the expensive reasoning is opt-in. The passive layer cannot
navel-gaze because it does no reasoning — it just writes a timestamped line.

---

## Detection triggers

### Lane A — friction (earns a *Breadcrumb*)
The bar is **a pattern, not a one-off**. Note it; the threshold check happens at analysis time.

| Pattern | Smell | Example |
|---|---|---|
| **Repeated manual work** | Same multi-step task done by hand 3+ times | Migrating lookup tables one-by-one with no script |
| **Ad-hoc process** | A multi-step workflow with no skill guiding it | Building views/TVFs from a schema with no guiding skill |
| **Skill fell short** | An existing skill didn't cover what was needed | `create-diagram` is Mermaid-only; needed a C4 model |
| **Recurring error** | The same class of mistake keeps happening | Invented enum/ID format caught by operator after a "fix" |
| **Manual bridge** | Unstructured work between two skills | Schema design → developer handoff with no spec |
| **Post-mortem** | Something broke that a skill could have prevented | Seed generation failed on a circular dependency |

### Lane B — success (earns a *Workflow candidate*)
Note a workflow when it (a) had **no guiding skill**, (b) produced a **clean result** (operator
confirmed / drill passed / no rework), and (c) will **plausibly repeat**.

| Signal | Why it matters |
|---|---|
| **No skill guided it** | A repeatable workflow with no home is a gap waiting to cost time again |
| **Clean result** | Confirmed by operator / passing drill / no rework — proof it's worth keeping |
| **Repetition likely** | Will recur across modules, projects, or clients |
| **Independent re-derivation** | If sessions keep reinventing the same sequence, that's the strongest signal to bundle it |

**Threshold + batching (the noise guard, both lanes):** a passive note is just a record. It
becomes a proposal only when (a) the operator runs the command, (b) it recurs 3+ times, or
(c) `weekly-review` sweeps it up. A single success isn't automatically a skill. Never interrupt
active work to raise a proposal — that is the failure mode this design exists to prevent.

---

## Steps — `/check-improvements`

1. Read `memory/improvement-backlog.md`. Note `Next-ID` (`SKL-NNN`) and `Next-WFC` (`WFC-NNN`).
2. Search claude-mem for related lessons (`mem search "[topic]"`) — a recurring root cause already
   noted as feedback strengthens the case.
3. **Lane A — friction.** Cluster *Breadcrumbs* by root cause (five "did X by hand again" lines about
   one gap = ONE proposal). Pull in friction surfaced this session. Write a `SKL-` proposal per
   cluster that clears the threshold. Be honest about effort/payoff — break-even "never" → recommend
   **Do nothing**, not a new skill.
4. **Lane B — success.** Review *Workflow candidates* + clean workflows from this session.
   Reconstruct the **actual** step sequence (including the corrections that made it work — those are
   often the valuable part). Judge generalizability. Write a `WFC-` proposal per candidate that
   clears the bar.
5. Apply the **triple lens** to each proposal: does it hurt/help SA, PM, or DBA work (or system health)?
6. Present proposals ranked by priority (both lanes). Recommend the top actions. **STOP** — building
   any skill or codifying any workflow is a Tier 1 deliverable and needs its own confirmation.
7. Move acted-on / rejected items to *Resolved* with the outcome; increment `Next-ID` / `Next-WFC`
   for every ID minted.

---

## Proposal output formats

### `SKL-` (Lane A — fix/build/enhance)
```
SKL-NNN — [short title]                                   Priority: 🔴/🟡/🟢
─────────────────────────────────────────────────────────────────────────
Problem:     [the friction, with a concrete example from the breadcrumbs]
Frequency:   [per-session / per-project / per-client]
Impact:      [what it costs if unfixed — time, rework, errors]
Lens:        [SA / PM / DBA / system-health]

Options:
  A. New skill            — build from scratch
  B. Enhance existing     — [which skill] + [what changes]
  C. Standing instruction — a rule in CLAUDE.md, no new file
  D. Do nothing           — accept the friction (sometimes correct)

Pros / Cons:   [one line each option]
Effort vs payoff:  Build [S/M/L] · Payoff/use [S/M/L] · Break-even ~[N] uses
Working analogy:   "Right now you [pain]; this would be like [comparison]."
Recommendation: [A/B/C/D] — [one line]
Dependencies:   [other skills / restructuring first — or "none"]
```

### `WFC-` (Lane B — codify success)
```
WFC-NNN — [workflow name]
─────────────────────────────────────────────────────────────────────────
Pattern:          [the step sequence actually taken]
Observed:         [N times, across which projects/sessions]
Success evidence: [drill pass / operator approval / no rework]
Generalizability: project-specific │ cross-project │ universal

Recommendation:
  A. New skill            — full skill file (skeleton below)
  B. Skill chain / pattern— sequence of existing skills + the glue, or a pattern inside a skill
  C. Standing instruction — lightweight rule / convention in CLAUDE.md or an existing skill
  D. Log only             — not enough evidence yet; keep observing

Draft skeleton (if A/B):  [Purpose / Trigger / Steps outline]
Dependencies:             [existing skills it builds on]
```

---

## The backlog — `memory/improvement-backlog.md`
Passive notes cost nothing:
```
- 2026-06-24 · repeated-manual-work · migrated 40 lookup tables by hand, no script · [myps]   (Breadcrumb)
- 2026-06-25 · Transactional routing drill (force states → verify → ROLLBACK) worked clean · [system]  (Workflow candidate)
```
Format: `- YYYY-MM-DD · <pattern-or-name> · <one-line observation> · [client or "system"]`.
No IDs at capture time — `SKL-`/`WFC-` IDs are minted only when promoted during `/check-improvements`.

---

## Integration

| Hooks into | How |
|---|---|
| `weekly-review` | System self-audit runs `/check-improvements` over the backlog; folds the top `SKL-`/`WFC-` into the digest. |
| `learn-from-feedback` | A correction the operator makes twice is a Lane A trigger → breadcrumb. |
| `end-of-task` | Quick pass: did this task hit a friction pattern (Lane A) **or** complete a clean unguided repeatable workflow (Lane B)? If so, one note before closing. |
| Quality Gate | Asks: "Did anything this session earn a breadcrumb or a workflow candidate?" |
| `new-skill` | Receives an approved `SKL-` (Option A) or `WFC-` (Option A/B) and builds it. |

---

## Self-referential rule (this skill audits itself)
This skill is not exempt from its own radar — both lanes. If `/check-improvements` produces
proposals that never get acted on, if the format is too heavy, if breadcrumbs/candidates aren't
captured where they should be, or if a lane keeps missing things the operator catches — **raise a
`SKL-` against this skill.** The loop that can't improve itself is the first thing to fix.

---

## Quality checklist
- [ ] Every proposal traces to real notes or in-session events — none invented
- [ ] Lane A clusters merged by root cause (no duplicate proposals for one gap)
- [ ] Lane B reconstructs the real sequence incl. the corrections that made it work
- [ ] Generalizability judged honestly — project-specific patterns stay in the client folder
- [ ] Each proposal has honest effort/payoff and a clear recommendation (incl. "Do nothing" / "Log only")
- [ ] Threshold respected — one-offs stay as notes, not proposals
- [ ] `Next-ID` / `Next-WFC` incremented; resolved items moved out of the active lists
- [ ] Nothing built or codified without a separate Tier 1 confirmation

## Failure exit
"Backlog is empty and nothing surfaced this session — no friction to fix, no workflow to codify.
I'll keep dropping breadcrumbs and workflow candidates as they come up; run `/check-improvements`
again after more work."
