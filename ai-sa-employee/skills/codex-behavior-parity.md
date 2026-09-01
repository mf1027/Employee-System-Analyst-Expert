# Skill: codex-behavior-parity

## Purpose

Translate useful ChatGPT/Codex operating behaviors into Claude-side MYPS work rules without
pretending Claude has Codex's exact runtime capabilities.

Use this skill when the operator asks Claude to work "like Codex", sync with Codex, copy Codex's
testing/review discipline, or prepare Claude to plan work that Codex or a developer may implement.

This is a parity and coordination skill, not a blanket implementation authorization or a blanket
restriction. It classifies which Codex behaviors Claude can execute directly in the current
environment versus which need a plan, an operator go-signal, or a handoff — it does not itself
grant or deny any specific code/DB/git action; those stay governed by the workspace's normal
gating (Instruction #1, SKL-017 plan-gate). *Corrected 2026-08-25, ADR-121 — this originally said
the skill "does not authorize code changes, database changes, git operations, or frontend work" at
all, contradicted by continuous practice the same day.*

## Canonical shared behavior layer (2026-08-31)

Portable observable behavior is now authored once at:

`C:\Users\khen\.agents\skills\gstack\model-overlays\shared.md`

Its stable `BHV-001`–`BHV-016` invariants cover authority classification, evidence-first
exploration, clarification thresholds, decision quality, Plan Mode separation, capability honesty,
workspace/destructive safety, tool and skill discipline, bounded persistence, communication,
verification, current-information integrity, privacy, and truthful failure reporting. Claude and GPT
model overlays inherit that contract and retain only runtime-specific adaptations.

Do not copy or independently rewrite the full contract in this MYPS skill. This file owns the
MYPS-specific portability workflow and readiness/memory requirements. Validate the shared layer
with `bun run behavior:check` from the gstack source; the command reports invariant provenance,
Claude/Codex generated targets, and freshness without storing user conversations or private
reasoning.

## Trigger phrases

- "make Claude work like Codex"
- "sync Claude and Codex behavior"
- "Codex personal behavior"
- "what does Codex do that Claude should follow"
- "handoff this to Claude but keep it Codex-style"
- "make Claude use the same process as ChatGPT/Codex"

## Required workflow

### 1. Reconcile current MYPS authority

Before producing a plan or handoff, read or verify the current authority surfaces:

1. Current operator instruction.
2. Obsidian MYPS startup notes and current-state dashboard.
3. `CODEX_SYNC_STARTUP.md`.
4. Relevant MYPS ADR/RISK/memory lane files.
5. Live code/config/schema evidence when the task is implementation-related.

If sources conflict, stop and report a conflict card before deciding which behavior to copy.

### 2. Inventory Codex behavior in scope

List the Codex behaviors the task needs, using only behaviors actually relevant to the request:

- plan-first for risky, multi-file, DB, deployment, or unclear work;
- file/config/schema inspection before asking discoverable questions;
- safe local execution with approvals;
- no unrequested git mutation;
- no production DB mutation;
- DB target reconciliation before connecting;
- rollback-only drills for DB/data checks;
- authenticated API tests before readiness claims;
- fresh file/function/line evidence;
- skill-based workflows such as `code-behavior-audit` and `rollback-readiness-test`;
- Obsidian mind-map update before completion.

### 3. Classify portability

For each behavior, classify it:

- **Portable** — Claude can follow the same instruction directly.
- **Workflow-equivalent** — Claude can plan/specify the behavior, but Codex/developer may execute it.
- **Claude Code only** — possible only when Claude has local tool access and explicit permission.
- **Not portable** — runtime-specific Codex behavior; document the limitation.
- **Operator-only** — requires the operator to approve, provide credentials, or run something.

### 4. Translate into Claude rules

Create Claude-facing instructions using this pattern:

```text
Codex behavior:
Claude equivalent:
Evidence required:
Limits / what Claude must not claim:
Obsidian note to update:
```

Hard rule *(corrected 2026-08-25, ADR-121 — the original version assumed Claude's capabilities are a
strict subset of Codex's, which is false in this environment; Claude Code has direct file, build,
and DB execution capability, and the original wording manufactured unnecessary handoffs for work
Claude could do directly)*:

```text
When a MYPS task asks Claude to behave like Codex, Claude must state plainly, from the CURRENT
environment's actual capability, what it can and cannot execute directly — never assume parity means
"less capable than Codex" or "more capable than Codex" by default. Where Claude genuinely can perform
the behavior (file edits, builds, read-only or approved DB actions, git operations under the normal
gating), it does so directly rather than fabricating a handoff. Where it genuinely cannot (Codex-only
runtime, sandboxed tools Claude has no equivalent for), it says so and produces a precise handoff
instead of pretending. Never fabricate capability in either direction.
```

### 5. Run RCA + gap loop

Before finalizing, run at least two passes:

1. **RCA pass** — why could Claude and Codex still drift after this translation?
2. **Gap pass** — what behavior is still unmapped, ambiguous, or unsupported?
3. Tighten wording or mark the gap as open.

Stop only when every behavior is implemented, mapped to an existing skill, marked not portable, or
left as an explicit operator decision.

### 5b. Auditing an already-shipped counterpart implementation (WFC-016)

When Codex (or the operator, or a prior Claude session) has already built something in this
workspace and the task is to independently review it — not to design from scratch — run this
sequence instead of a fresh design pass:

1. **Discover the real artifact set via git/file forensics**, not the other agent's own summary of
   what it did. A prior session's report can be stale or wrong by the time you check (a file it
   called untracked may have since been committed elsewhere).
2. **Enumerate what it got right and commit to preserving it — before naming a single defect.**
   Skipping this step turns an audit into a rewrite.
3. **RCA each defect to one root cause**, not a symptom list. One false premise can generate
   several surface-level findings; fix the premise, not each symptom separately.
4. **Reverse-gap analysis:** does adopting the counterpart's discipline degrade Claude's own
   capability? This is the check that catches the specific failure mode this skill exists to avoid
   — importing a restriction that doesn't actually apply here.
5. **Verify the counterpart's factual claims about work outside your inspectable tree** rather than
   trusting them (e.g. a claimed update to the other agent's own config — check it directly).
6. **Classify what you genuinely cannot observe as `UNOBSERVABLE`**, not guessed.
7. **Fix in place what's fixable; hand off only what's genuinely out of scope** (global files,
   another agent's runtime).

4th+ sighting of this shape against the same counterpart agent (ADR-101, ADR-103, ADR-104, and the
2026-08-25/26 parity-layer audit that corrected this skill's own original hard rule). Steps 4 and 2
are the genuinely novel bits over a plain RCA — the rest reuses `deep-analysis`.

### 6. Completion and sync

For MYPS, update or instruct the update of relevant Obsidian notes before the task is complete:

- Claude/Codex sync guide;
- current-state dashboard;
- skill/process notes;
- backend/testing/change-impact notes when behavior affects implementation work.

Final response must include the MYPS mind-map sync block — canonical rule (ADR-124): vault
`Claude + Codex Real-Time Sync Protocol.md` → "Completion Gate".

For a behavior-parity implementation, completion additionally requires:

- `bun run behavior:check` passes;
- deterministic behavior-contract tests pass;
- Claude and Codex generated host outputs are fresh and use the correct model overlay chain;
- global Claude rules contain the bounded generated contract block;
- Codex can discover the MYPS-only readiness vocabulary through `~/.codex/AGENTS.md`;
- any unavailable model-dependent E2E check is named as an unverified boundary.

## Output format

```text
Codex-to-Claude parity result

RCA:
- ...

Gap analysis:
- ...

Behavior matrix:
- Codex behavior:
  Claude equivalent:
  Portability:
  Evidence:
  Limitation:

Updated/required docs:
- ...

Remaining open decisions:
- ...

Mind-map sync:
- Updated:
- Notes touched:
- If no:
```

## Guardrails

- **Zero AI-tooling footprint in `project_myps` (ADR-107, absolute — not operator-overridable,
  unlike the rules below).** Two halves, both required, restated here self-contained so this rule
  travels with a clone of this repo rather than depending on the operator's personal global config:
  (1) no new/modified Markdown files in `project_myps`'s source tree; (2) no new AI-coordination-
  tooling files either — a fresh `AGENTS.md`, a fresh `.claude/hooks/` directory, a fresh
  `.claude/settings.json` hooks block, etc. **Documented exceptions:** `documents\plans\<slug>.md`
  (the repo's own pre-existing `/create-plan` output, unrelated to this rule) and the pre-existing
  `project_myps/.claude/skills/` dev pipeline + its `.claude/settings.json` `permissions.allow`
  array (confirmed pre-existing, not something to delete/"clean up" under this rule).
- **No AI-committed changes to `Main/appsettings.Development.json` without asking, every time
  (2026-08-25).** Never `git commit` (or stage for commit) a change to that file inside
  `project_myps` without the operator's explicit go-ahead **for that specific commit** — it carries
  a known-exposed credential (RISK-090/091). Applies to Claude and Codex alike, regardless of which
  agent is doing the committing. The operator's own manual commits to this file are unrestricted;
  this rule binds the AI, not the human.
- **A `SessionStart` (or equivalent automated context-injection) hook is a reminder, not a
  substitute.** If a hook auto-injects a summary of MYPS state at session start, treat it as a
  prompt to go read the real sources (Obsidian entry points, `decisions.md`/`risks.md`,
  `CODEX_SYNC_STARTUP.md`) — never as a replacement for actually reading them.
- Git operations (commit, push, reset, checkout, staging) are available when the operator directs
  them, under the workspace's normal safety rules — never run unrequested, never force/destructive
  without explicit confirmation. *Corrected 2026-08-25, ADR-121 — was an absolute "do not run"
  ban, contradicted by routine practice.*
- DB mutation requires the current task's explicit approval and the workspace's active DB-safety
  target (`CODEX_SYNC_STARTUP.md`) — same rule as every other skill, not a parity-specific
  restriction.
- Do not convert Claude into a fake Codex runtime **in either direction** — never claim inability to
  do something Claude Code can actually do here, and never claim a Codex-only capability Claude
  does not have.
- Do not mark a workflow "100% synced" unless startup, completion, Obsidian, and evidence gates are
  all represented.
