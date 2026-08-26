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

### 6. Completion and sync

For MYPS, update or instruct the update of relevant Obsidian notes before the task is complete:

- Claude/Codex sync guide;
- current-state dashboard;
- skill/process notes;
- backend/testing/change-impact notes when behavior affects implementation work.

Final response must include the MYPS mind-map sync block.

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

- Do not create or modify Markdown inside `project_myps` (ADR-107, absolute — not operator-
  overridable, unlike the rules below).
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
